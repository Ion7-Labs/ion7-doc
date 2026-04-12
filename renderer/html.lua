--- ion7-doc HTML renderer

local renderer = {}
local theme    = require "themes.dark"

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function write_file(path, content)
    local f, err = io.open(path, "w")
    if not f then error("[ion7-doc] cannot write " .. path .. ": " .. (err or "?")) end
    f:write(content)
    f:close()
end

local function escape(s)
    if not s then return "" end
    return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function short_name(fr)
    if fr.module and fr.module.name then
        local n = fr.module.name:gsub("^ion7%.core%.?", "")
        return n ~= "" and n or "ion7.core"
    end
    return (fr.path or ""):match("([^/]+)%.lua$") or "?"
end

local function html_filename(fr)
    local name = short_name(fr):gsub("[%./]", "_")
    return (name ~= "" and name or "ion7_core") .. ".html"
end

-- ── Sidebar ───────────────────────────────────────────────────────────────────

local function build_sidebar(corpus, current)
    local order  = {}
    local groups = {}

    for _, fr in ipairs(corpus) do
        local name = short_name(fr)
        local seg  = name:match("^([^.]+)") or name

        if not groups[seg] then
            groups[seg] = {}
            order[#order + 1] = seg
        end
        for _, s in ipairs(order) do
            if s == seg then
                groups[seg][#groups[seg] + 1] = fr
                break
            end
        end
    end

    -- "Home" link always first
    local home_active = (current == nil)
    local html = {}
    html[#html + 1] = '<div class="mb-5 px-2">'
        .. theme.sidebar_link("index.html", "README", home_active)
        .. '</div>\n'

    for _, seg in ipairs(order) do
        local items = {}
        for _, fr in ipairs(groups[seg]) do
            local active  = (fr == current)
            local name    = short_name(fr)
            local display = name:find("%.") and name:match("%.(.+)$") or name
            items[#items + 1] = theme.sidebar_link(html_filename(fr), display, active)
        end
        html[#html + 1] = theme.sidebar_section(seg == "ion7_core" and "core" or seg, table.concat(items))
    end

    return table.concat(html)
end

-- ── Module page ───────────────────────────────────────────────────────────────

local function render_module_page(fr, corpus, out_dir)
    local name    = short_name(fr)
    local sidebar = build_sidebar(corpus, fr)
    local bc      = theme.breadcrumb({
        { href = "index.html", label = "ion7-core" },
        { label = name },
    })

    local mod  = fr.module
    local parts = {}
    parts[#parts + 1] = theme.html_open(name)
    parts[#parts + 1] = theme.layout_open(sidebar, bc)

    -- Page header
    local kind_label = "module"
    local page_name  = name
    local page_desc  = mod and mod.description or ""

    if #fr.classes == 1 and fr.classes[1].name then
        kind_label = "class"
        page_name  = fr.classes[1].name
    end

    parts[#parts + 1] = theme.page_header(kind_label, escape(page_name), escape(page_desc))

    -- Module-level @usage
    if mod then
        for _, t in ipairs(mod.tags or {}) do
            if t.tag == "usage" then
                parts[#parts + 1] = theme.usage_block(t.lines)
            end
        end
    end

    -- Classes / fields
    for _, cls in ipairs(fr.classes) do
        if #fr.classes > 1 then
            parts[#parts + 1] = theme.section_title(escape(cls.name or "class"))
        end
        if cls.description and cls.description ~= "" then
            parts[#parts + 1] = theme.p(escape(cls.description))
        end
        parts[#parts + 1] = theme.fields_block(cls.tags or {})
    end

    -- Functions — quick-nav then cards with dividers
    if #fr.functions > 0 then
        parts[#parts + 1] = theme.section_title("Functions")

        -- Quick-nav
        local navitems = {}
        for _, fn in ipairs(fr.functions) do
            navitems[#navitems + 1] = {
                anchor = (fn.name or "fn"):gsub("[^%w_]", "_"),
                label  = fn.name or "?",
            }
        end
        parts[#parts + 1] = theme.quicknav(navitems)

        -- Cards separated by dividers
        for i, fn in ipairs(fr.functions) do
            parts[#parts + 1] = theme.fn_card(fn)
            if i < #fr.functions then
                parts[#parts + 1] = '<div class="fn-divider"></div>\n'
            end
        end
    end

    parts[#parts + 1] = theme.layout_close()
    parts[#parts + 1] = theme.html_close()

    local out = out_dir .. "/" .. html_filename(fr)
    write_file(out, table.concat(parts))
    return out
end

-- ── Index page (API homepage) ─────────────────────────────────────────────────

local function render_index(corpus, out_dir)
    local sidebar = build_sidebar(corpus, nil)

    -- Stats
    local total_fns = 0
    for _, fr in ipairs(corpus) do total_fns = total_fns + #fr.functions end

    -- Categorize modules into groups
    local cat_order  = { "Model", "Context", "Vocab", "Sampler", "Utilities" }
    local cat_groups = {}
    for _, c in ipairs(cat_order) do cat_groups[c] = {} end

    for _, fr in ipairs(corpus) do
        local name    = short_name(fr)
        local display = name:find("%.") and name:match("%.(.+)$") or name
        local desc    = ""
        if fr.module and fr.module.description then
            desc = fr.module.description:match("^([^\n]+)") or ""
            if #desc > 90 then desc = desc:sub(1, 87) .. "..." end
        end
        local entry = {
            href    = html_filename(fr),
            display = display,
            n_fns   = #fr.functions,
            desc    = escape(desc),
        }
        local cat
        if     name:match("^model")                                    then cat = "Model"
        elseif name:match("^context")                                  then cat = "Context"
        elseif name == "vocab"                                         then cat = "Vocab"
        elseif name:match("^sampler") or name == "custom_sampler"      then cat = "Sampler"
        else                                                                cat = "Utilities"
        end
        cat_groups[cat][#cat_groups[cat] + 1] = entry
    end

    local parts = {}
    parts[#parts + 1] = theme.html_open("ion7-core — API Reference")
    parts[#parts + 1] = theme.layout_open(sidebar, '<span class="text-zinc-500">ion7-core</span>')
    parts[#parts + 1] = theme.api_index(#corpus, total_fns, cat_order, cat_groups)
    parts[#parts + 1] = theme.layout_close()
    parts[#parts + 1] = theme.html_close()

    write_file(out_dir .. "/index.html", table.concat(parts))
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Build and write search-index.json
local function write_search_index(corpus, out_dir)
    local entries = {}
    for _, fr in ipairs(corpus) do
        local href = html_filename(fr)
        local mod  = short_name(fr)
        for _, fn in ipairs(fr.functions) do
            if fn.name then
                local anchor = fn.name:gsub("[^%w_]", "_")
                local desc   = fn.description or ""
                if #desc > 80 then desc = desc:sub(1, 77) .. "..." end
                -- Minimal JSON encoding (no special chars in names/descs expected)
                local function js(s)
                    return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', ' ')
                end
                entries[#entries + 1] = string.format(
                    '{"name":"%s","module":"%s","href":"%s#%s","desc":"%s"}',
                    js(fn.name), js(mod), js(href), js(anchor), js(desc))
            end
        end
    end
    local json = "[\n" .. table.concat(entries, ",\n") .. "\n]\n"
    write_file(out_dir .. "/search-index.json", json)
    io.write("[ion7-doc] search-index.json (" .. #entries .. " entries)\n")
end

-- ── Landing page ──────────────────────────────────────────────────────────────

local function render_landing(corpus, out_dir)
    local html = theme.landing_page(corpus)
    write_file(out_dir .. "/index.html", html)
end

--- @param  corpus       table    From parser.parse_dir().
--- @param  out_dir      string   Output directory (must exist).
--- @param  readme_path  string?  Path to README.md to use as index.
function renderer.render(corpus, out_dir, readme_path)
    out_dir = out_dir:gsub("/$", "")
    local api_dir = out_dir .. "/api"
    os.execute('mkdir -p "' .. api_dir .. '"')

    write_search_index(corpus, api_dir)
    render_index(corpus, api_dir)
    for _, fr in ipairs(corpus) do
        local out = render_module_page(fr, corpus, api_dir)
        io.write("[ion7-doc] " .. out .. "\n")
    end

    render_landing(corpus, out_dir)
    io.write("[ion7-doc] landing → " .. out_dir .. "/index.html\n")
    io.write("[ion7-doc] api     → " .. api_dir .. "/index.html\n")
end

return renderer
