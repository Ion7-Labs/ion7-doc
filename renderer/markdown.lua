--- ion7-doc Markdown renderer
---
--- Renders the parser's structured output to plain-Lua markdown files,
--- one per source file. Designed for Obsidian-friendly consumption :
--- flat directory layout, wikilinks for cross-references, idiomatic
--- markdown headings.
---
--- Output shape (under `out_dir/`) :
---
---   README.md                      ← landing page : module index + counts
---   <module-name>.md               ← one per parsed file (e.g. ion7.rag.db.chunks.md)
---
--- Each file's heading hierarchy :
---   # ion7.rag.db.chunks            ← H1 = module name
---   > Source : `src/...`
---   <description>
---   ## Classes
---     ### ClassName
---     **Fields :** ...
---   ## Functions
---     ### `M.fn(args) → returns`
---     description
---     **Parameters :** ...
---     **Returns :** ...
---     **Raises :** ...
---     **Usage :** ```lua...```

local renderer = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function write_file(path, content)
    local f, err = io.open(path, "w")
    if not f then error("[ion7-doc] cannot write " .. path .. ": " .. (err or "?")) end
    f:write(content)
    f:close()
end

local function module_filename(file_result)
    if file_result.module and file_result.module.name then
        return file_result.module.name .. ".md"
    end
    -- Fall back to the file basename without .lua extension.
    local base = (file_result.path or ""):match("([^/]+)%.lua$") or "module"
    return base .. ".md"
end

local function module_label(file_result)
    if file_result.module and file_result.module.name then
        return file_result.module.name
    end
    return (file_result.path or ""):match("([^/]+)%.lua$") or "(anonymous)"
end

local function escape_inline(s)
    return (s or ""):gsub("|", "\\|")
end

-- ── Per-element renderers ─────────────────────────────────────────────────────

local function render_description(buf, item)
    if item.description and item.description ~= "" then
        buf[#buf + 1] = item.description
        buf[#buf + 1] = ""
    end
end

local function tags_of(item, name)
    local out = {}
    for _, t in ipairs(item.tags or {}) do
        if t.tag == name then out[#out + 1] = t end
    end
    return out
end

--- Strip a single shared leading indent across a list of continuation
--- lines, so the rendered block doesn't carry the visual prefix the
--- source uses to keep them aligned with the `@tag` line.
local function dedent(lines)
    if not lines or #lines == 0 then return lines end
    local min_indent = math.huge
    for _, l in ipairs(lines) do
        if l:match("%S") then
            local n = #(l:match("^( *)") or "")
            if n < min_indent then min_indent = n end
        end
    end
    if min_indent == math.huge or min_indent == 0 then return lines end
    local out = {}
    for i, l in ipairs(lines) do
        out[i] = l:sub(min_indent + 1)
    end
    return out
end

--- Render the multi-line continuation body of a tag. Inside a list
--- item, a 4-space indent past the bullet (= 6 spaces total when the
--- bullet uses `- `) is the CommonMark recipe for an indented code
--- block — preserves alignment, escapes wikilinks and underscores, no
--- nested-fence ambiguity.
local function render_continuation(buf, cont)
    if not cont or #cont == 0 then return end
    while cont[#cont] == "" do cont[#cont] = nil end
    if #cont == 0 then return end
    local lines = dedent(cont)
    buf[#buf + 1] = ""
    for _, l in ipairs(lines) do buf[#buf + 1] = "      " .. l end
    buf[#buf + 1] = ""
end

local function render_params(buf, item)
    local params = tags_of(item, "param")
    if #params == 0 then return end
    buf[#buf + 1] = "**Parameters :**"
    buf[#buf + 1] = ""
    for _, p in ipairs(params) do
        local name = p.name or "?"
        local typ  = p.type and (" `" .. p.type .. "`") or ""
        local desc = p.desc and (" — " .. p.desc) or ""
        buf[#buf + 1] = "- `" .. name .. "`" .. typ .. desc
        render_continuation(buf, p.cont)
    end
    buf[#buf + 1] = ""
end

local function render_returns(buf, item)
    local rets = tags_of(item, "return")
    if #rets == 0 then return end
    if #rets == 1 then
        local r = rets[1]
        local typ = r.type and ("`" .. r.type .. "`") or ""
        local desc = r.desc and (" — " .. r.desc) or ""
        buf[#buf + 1] = "**Returns :** " .. typ .. desc
        render_continuation(buf, r.cont)
    else
        buf[#buf + 1] = "**Returns :**"
        buf[#buf + 1] = ""
        for _, r in ipairs(rets) do
            local typ = r.type and ("`" .. r.type .. "`") or ""
            local desc = r.desc and (" — " .. r.desc) or ""
            buf[#buf + 1] = "- " .. typ .. desc
            render_continuation(buf, r.cont)
        end
    end
    buf[#buf + 1] = ""
end

local function render_errors(buf, item)
    local errs = tags_of(item, "error")
    if #errs == 0 then return end
    if #errs == 1 then
        buf[#buf + 1] = "**Raises :** " .. (errs[1].desc or "")
    else
        buf[#buf + 1] = "**Raises :**"
        for _, e in ipairs(errs) do
            buf[#buf + 1] = "- " .. (e.desc or "")
        end
    end
    buf[#buf + 1] = ""
end

local function render_usage(buf, item)
    for _, t in ipairs(item.tags or {}) do
        if t.tag == "usage" then
            buf[#buf + 1] = "**Usage :**"
            buf[#buf + 1] = "```lua"
            for _, line in ipairs(t.lines or {}) do buf[#buf + 1] = line end
            buf[#buf + 1] = "```"
            buf[#buf + 1] = ""
        end
    end
end

local function render_function(buf, fn)
    local sig = fn.signature or fn.name or "(anonymous)"
    buf[#buf + 1] = "### `" .. sig .. "`"
    buf[#buf + 1] = ""
    render_description(buf, fn)
    render_params(buf, fn)
    render_returns(buf, fn)
    render_errors(buf, fn)
    render_usage(buf, fn)
end

local function render_class(buf, cls)
    buf[#buf + 1] = "### " .. (cls.name or "(unnamed class)")
    buf[#buf + 1] = ""
    render_description(buf, cls)
    -- Fields declared on the class itself.
    local fields = tags_of(cls, "field")
    if #fields > 0 then
        buf[#buf + 1] = "**Fields :**"
        buf[#buf + 1] = ""
        for _, f in ipairs(fields) do
            local name = f.name or "?"
            local typ  = f.type and (" `" .. f.type .. "`") or ""
            local desc = f.desc and (" — " .. f.desc) or ""
            buf[#buf + 1] = "- `" .. name .. "`" .. typ .. desc
        end
        buf[#buf + 1] = ""
    end
end

-- ── Per-file renderer ─────────────────────────────────────────────────────────

local function render_file(file_result)
    local buf = {}
    local label = module_label(file_result)

    buf[#buf + 1] = "# " .. label
    buf[#buf + 1] = ""
    if file_result.path then
        buf[#buf + 1] = "> Source : `" .. file_result.path .. "`"
        buf[#buf + 1] = ""
    end

    -- Module-level description.
    if file_result.module then
        render_description(buf, file_result.module)
    end

    -- Classes.
    if #file_result.classes > 0 then
        buf[#buf + 1] = "## Classes"
        buf[#buf + 1] = ""
        for _, cls in ipairs(file_result.classes) do
            render_class(buf, cls)
        end
    end

    -- Functions. Skip Lua-private (underscore-prefixed) names ; group
    -- the remainder into instance methods (`Class:fn`) and module-level
    -- (`M.fn` / `Class.fn`) so navigation is easier.
    local public, methods = {}, {}
    for _, fn in ipairs(file_result.functions) do
        local sig = fn.signature or fn.name or ""
        local short = sig:match("([^%.%:]+)%(") or sig
        if not short:match("^_") then
            if sig:find(":", 1, true) then
                methods[#methods + 1] = fn
            else
                public[#public + 1] = fn
            end
        end
    end

    if #methods > 0 then
        buf[#buf + 1] = "## Methods"
        buf[#buf + 1] = ""
        for _, fn in ipairs(methods) do render_function(buf, fn) end
    end
    if #public > 0 then
        buf[#buf + 1] = "## Functions"
        buf[#buf + 1] = ""
        for _, fn in ipairs(public) do render_function(buf, fn) end
    end

    -- Standalone fields (rare ; module-level @field declarations).
    if #file_result.fields > 0 then
        buf[#buf + 1] = "## Fields"
        buf[#buf + 1] = ""
        for _, f in ipairs(file_result.fields) do
            local first_field = (f.tags and f.tags[1]) or f
            local name = (first_field.name or f.name) or "?"
            local typ  = first_field.type and (" `" .. first_field.type .. "`") or ""
            local desc = first_field.desc and (" — " .. first_field.desc) or ""
            buf[#buf + 1] = "- `" .. name .. "`" .. typ .. desc
        end
        buf[#buf + 1] = ""
    end

    -- Trim trailing blank lines.
    while buf[#buf] == "" do buf[#buf] = nil end
    buf[#buf + 1] = ""
    return table.concat(buf, "\n")
end

-- ── Index (README.md) ─────────────────────────────────────────────────────────

local function render_index(corpus, opts)
    local buf = {}
    local label = opts.label or "ion7"
    buf[#buf + 1] = "# " .. label .. " — API reference"
    buf[#buf + 1] = ""
    if opts.desc and opts.desc ~= "" then
        buf[#buf + 1] = opts.desc
        buf[#buf + 1] = ""
    end
    buf[#buf + 1] = "Generated from `--- @module / @class / @field / @param / " ..
                   "@return / @error / @usage` doc comments. " ..
                   "Re-run `gendoc-md` after refactors to keep this in sync."
    buf[#buf + 1] = ""
    buf[#buf + 1] = "## Modules"
    buf[#buf + 1] = ""
    buf[#buf + 1] = "| Module | Source | Classes | Functions |"
    buf[#buf + 1] = "|--------|--------|--------:|----------:|"

    -- Sort the corpus alphabetically by module name for stable output.
    local sorted = {}
    for _, fr in ipairs(corpus) do sorted[#sorted + 1] = fr end
    table.sort(sorted, function(a, b)
        return module_label(a) < module_label(b)
    end)

    for _, fr in ipairs(sorted) do
        local label2 = module_label(fr)
        local link = "[[" .. label2 .. "]]"
        local src = fr.path and ("`" .. fr.path .. "`") or "?"
        local n_cls = #fr.classes
        local n_fn  = #fr.functions
        buf[#buf + 1] = string.format("| %s | %s | %d | %d |",
            link, escape_inline(src), n_cls, n_fn)
    end
    buf[#buf + 1] = ""
    return table.concat(buf, "\n")
end

-- ── Public ────────────────────────────────────────────────────────────────────

--- Render a parsed corpus into a directory of markdown files.
---
--- @param  corpus  table   Output of `parser.parse_dir(...)`.
--- @param  out_dir string  Destination directory (must already exist).
--- @param  opts    table?  { label = "ion7-rag", desc = "one-liner" }
function renderer.render(corpus, out_dir, opts)
    opts = opts or {}

    -- Strip trailing slash for consistency.
    out_dir = out_dir:gsub("/+$", "")

    -- One file per module.
    for _, file_result in ipairs(corpus) do
        local fname = module_filename(file_result)
        write_file(out_dir .. "/" .. fname, render_file(file_result))
    end

    -- README.md index.
    write_file(out_dir .. "/README.md", render_index(corpus, opts))
end

return renderer
