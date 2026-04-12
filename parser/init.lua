--- ion7-doc parser
--- Extracts structured documentation from ion7-style Lua source files.
---
--- Comment format expected:
---   --- @module name
---   --- @class Name
---   --- @field name type description
---   --- @param name type description
---   --- @return type description
---   --- @usage
---   ---   code example
---   --- Plain description text (no tag = description line)
---
--- Usage:
---   local parser = require "parser"
---   local ast    = parser.parse_file("src/ion7/core/model.lua")
---   local corpus = parser.parse_dir("src/ion7/core")

local parser = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

--- Strip the `--- ` prefix from a doc comment line.
--- Returns nil if the line is not a doc comment.
local function strip_prefix(line)
    -- Match `---` optionally followed by a space and content
    return line:match("^%-%-%-%s?(.*)$")
end

--- Parse a single tag line like `@param name type description`
--- Returns tag, rest  (tag = "param", rest = "name type description")
local function parse_tag(text)
    local tag, rest = text:match("^@(%a[%a_%-]*)%s*(.*)")
    return tag, rest
end

--- Split `rest` into (name, type, description) for @param / @field tags.
--- Format: `name  type  description text`
local function split_param(rest)
    local name, type_and_desc = rest:match("^(%S+)%s+(.*)")
    if not name then return rest, nil, nil end
    local typ, desc = type_and_desc:match("^(%S+)%s+(.*)")
    if not typ then return name, type_and_desc, nil end
    return name, typ, desc
end

--- Split `rest` into (type, description) for @return tags.
local function split_return(rest)
    local typ, desc = rest:match("^(%S+)%s+(.*)")
    if not typ then return rest, nil end
    return typ, desc
end

-- ── Block collector ───────────────────────────────────────────────────────────

--- Collect contiguous `---` lines starting at line_i.
--- Returns: lines table (stripped content), next_i (first non-doc line index)
local function collect_block(lines, start_i)
    local block = {}
    local i = start_i
    while i <= #lines do
        local content = strip_prefix(lines[i])
        if content == nil then break end
        block[#block + 1] = content
        i = i + 1
    end
    return block, i
end

-- ── Block parser ──────────────────────────────────────────────────────────────

--- Parse a collected block of stripped doc lines into a structured item.
--- Returns a table:
---   { kind, name, description, tags[] }
--- where kind = "module"|"class"|"function"|"field"|"unknown"
local function parse_block(raw_lines, anchor_line)
    local item = {
        kind        = "unknown",
        name        = nil,
        description = {},    -- plain text lines before tags
        tags        = {},    -- {tag, ...}
        source_line = anchor_line,
    }

    local in_usage     = false
    local usage_lines  = {}
    local desc_done    = false   -- once we hit a tag, description is closed

    for _, raw in ipairs(raw_lines) do
        if raw == "" then
            if in_usage then
                usage_lines[#usage_lines + 1] = ""
            elseif not desc_done then
                item.description[#item.description + 1] = ""
            end
        else
            local tag, rest = parse_tag(raw)
            if tag then
                desc_done = true
                in_usage  = false

                if tag == "module" then
                    item.kind = "module"
                    item.name = rest:match("^%S+") or rest

                elseif tag == "class" then
                    item.kind = "class"
                    item.name = rest:match("^%S+") or rest

                elseif tag == "field" then
                    if item.kind == "unknown" then item.kind = "class_field" end
                    local name, typ, desc = split_param(rest)
                    item.tags[#item.tags + 1] = {
                        tag  = "field",
                        name = name,
                        type = typ,
                        desc = desc,
                    }

                elseif tag == "param" then
                    if item.kind == "unknown" then item.kind = "function" end
                    local name, typ, desc = split_param(rest)
                    item.tags[#item.tags + 1] = {
                        tag  = "param",
                        name = name,
                        type = typ,
                        desc = desc,
                    }

                elseif tag == "return" then
                    if item.kind == "unknown" then item.kind = "function" end
                    local typ, desc = split_return(rest)
                    item.tags[#item.tags + 1] = {
                        tag  = "return",
                        type = typ,
                        desc = desc,
                    }

                elseif tag == "error" then
                    item.tags[#item.tags + 1] = {
                        tag  = "error",
                        desc = rest,
                    }

                elseif tag == "usage" then
                    in_usage    = true
                    usage_lines = {}
                    item.tags[#item.tags + 1] = {
                        tag   = "usage",
                        lines = usage_lines,  -- shared ref, filled below
                    }

                else
                    -- Unknown tag — keep as-is for forward compat
                    item.tags[#item.tags + 1] = { tag = tag, rest = rest }
                end

            elseif in_usage then
                -- Inside @usage block: collect verbatim (strip 2-space indent if present)
                usage_lines[#usage_lines + 1] = raw:match("^  (.*)") or raw

            else
                if not desc_done then
                    item.description[#item.description + 1] = raw
                end
            end
        end
    end

    -- Join description lines into a single string
    -- Trim leading/trailing blank lines
    local d = item.description
    while d[1] == "" do table.remove(d, 1) end
    while d[#d] == "" do table.remove(d) end
    item.description = table.concat(d, "\n")

    return item
end

-- ── Lua signature extractor ───────────────────────────────────────────────────

--- Attempt to extract a function signature from the line immediately after the
--- doc block. Returns name and param string or nil.
local function extract_signature(code_line)
    if not code_line then return nil, nil end

    -- function Foo.bar(...)  /  function Foo:bar(...)
    local name, params = code_line:match("^%s*function%s+([%w_.:]+)%s*%((.-)%)")
    if name then return name, params end

    -- local function bar(...)
    name, params = code_line:match("^%s*local%s+function%s+([%w_]+)%s*%((.-)%)")
    if name then return name, params end

    -- Foo.bar = function(...)
    name, params = code_line:match("^%s*([%w_.:]+)%s*=%s*function%s*%((.-)%)")
    if name then return name, params end

    return nil, nil
end

-- ── File parser ───────────────────────────────────────────────────────────────

--- Parse a single Lua source file.
--- @param  path  string  Absolute or relative path to the .lua file.
--- @return table|nil  { path, module, classes[], functions[], fields[] }
--- @return string|nil  Error message on failure.
function parser.parse_file(path)
    local f, err = io.open(path, "r")
    if not f then
        return nil, "cannot open " .. path .. ": " .. (err or "?")
    end

    local lines = {}
    for line in f:lines() do
        lines[#lines + 1] = line
    end
    f:close()

    local result = {
        path      = path,
        module    = nil,
        classes   = {},
        functions = {},
        fields    = {},
        items     = {},   -- all items in source order
    }

    local i = 1
    while i <= #lines do
        local content = strip_prefix(lines[i])

        if content ~= nil then
            -- Start of a doc block
            local block_lines, next_i = collect_block(lines, i)
            local item = parse_block(block_lines, i)

            -- Attach the code signature from the line after the block
            -- Skip any blank lines between the doc block and the function definition
            local check_i = next_i
            while check_i <= #lines and lines[check_i]:match("^%s*$") do
                check_i = check_i + 1
            end
            local sig_name, sig_params = extract_signature(lines[check_i])
            if sig_name then
                item.signature = sig_name .. "(" .. (sig_params or "") .. ")"
                if item.kind == "unknown" then item.kind = "function" end
                if not item.name then item.name = sig_name end
            end

            -- Route to the right bucket
            if item.kind == "module" then
                result.module = item
            elseif item.kind == "class" then
                result.classes[#result.classes + 1] = item
            elseif item.kind == "function" then
                result.functions[#result.functions + 1] = item
            elseif item.kind == "field" or item.kind == "class_field" then
                result.fields[#result.fields + 1] = item
            end

            result.items[#result.items + 1] = item
            i = next_i
        else
            i = i + 1
        end
    end

    return result
end

-- ── Directory parser ──────────────────────────────────────────────────────────

--- Parse all .lua files in a directory (non-recursive).
--- @param  dir    string   Directory path.
--- @param  files  table?   Optional explicit list of file paths (overrides dir scan).
--- @return table           List of file result tables.
--- @return string|nil      Error message if directory scan failed.
function parser.parse_dir(dir, files)
    local results = {}

    if files then
        for _, path in ipairs(files) do
            local r, err = parser.parse_file(path)
            if r then
                results[#results + 1] = r
            else
                io.stderr:write("[ion7-doc] warning: " .. (err or path) .. "\n")
            end
        end
        return results
    end

    -- Fallback: scan directory with ls (portable, no lfs dep)
    local handle = io.popen('find "' .. dir .. '" -name "*.lua" | sort')
    if not handle then
        return results, "cannot scan " .. dir
    end
    for path in handle:lines() do
        local r, err = parser.parse_file(path)
        if r then
            results[#results + 1] = r
        else
            io.stderr:write("[ion7-doc] warning: " .. (err or path) .. "\n")
        end
    end
    handle:close()

    return results
end

return parser
