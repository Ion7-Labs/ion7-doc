--- ion7-doc HTML renderer

local renderer = {}
local theme    = require "themes.dark"

-- ── Per-render config (set by renderer.render opts) ──────────────────────────
-- Avoids threading opts through every local function signature.
local _cfg = {
    label  = "ion7-core",       -- human name shown in breadcrumbs/titles
    id     = "core",            -- short id used for cross-links ("core"|"grammar"|...)
    prefix = "ion7%.core%.?",   -- Lua pattern stripped from module names
    desc   = "",                -- one-liner shown on the API index page
}

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
        local n = fr.module.name:gsub("^" .. _cfg.prefix, "")
        return n ~= "" and n or _cfg.label
    end
    return (fr.path or ""):match("([^/]+)%.lua$") or "?"
end

local function html_filename(fr)
    local name = short_name(fr):gsub("[%./]", "_")
    if name == "" or name == _cfg.label:gsub("[%-]", "_") then
        -- root module: use label as filename prefix
        name = _cfg.label:gsub("[%-]", "_")
    end
    return name .. ".html"
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
        -- Normalise segment label: strip leading ion7_ / ion7- prefix
        local seg_label = seg:gsub("^ion7[_%-]?", "")
        seg_label = seg_label ~= "" and seg_label or _cfg.id
        html[#html + 1] = theme.sidebar_section(seg_label, table.concat(items))
    end

    return table.concat(html)
end

-- ── Module page ───────────────────────────────────────────────────────────────

local function render_module_page(fr, corpus, out_dir)
    local name    = short_name(fr)
    local sidebar = build_sidebar(corpus, fr)
    local bc      = theme.breadcrumb({
        { href = "index.html", label = _cfg.label },
        { label = name },
    })

    local mod  = fr.module
    local parts = {}
    parts[#parts + 1] = theme.html_open(name)
    parts[#parts + 1] = theme.layout_open(sidebar, bc)

    local kind_label = "module"
    local page_name  = name
    local page_desc  = mod and mod.description or ""

    if #fr.classes == 1 and fr.classes[1].name then
        kind_label = "class"
        page_name  = fr.classes[1].name
    end

    parts[#parts + 1] = theme.page_header(kind_label, escape(page_name), escape(page_desc))

    if mod then
        for _, t in ipairs(mod.tags or {}) do
            if t.tag == "usage" then
                parts[#parts + 1] = theme.usage_block(t.lines)
            end
        end
    end

    for _, cls in ipairs(fr.classes) do
        if #fr.classes > 1 then
            parts[#parts + 1] = theme.section_title(escape(cls.name or "class"))
        end
        if cls.description and cls.description ~= "" then
            parts[#parts + 1] = theme.p(escape(cls.description))
        end
        parts[#parts + 1] = theme.fields_block(cls.tags or {})
    end

    if #fr.functions > 0 then
        parts[#parts + 1] = theme.section_title("Functions")

        local navitems = {}
        for _, fn in ipairs(fr.functions) do
            navitems[#navitems + 1] = {
                anchor = (fn.name or "fn"):gsub("[^%w_]", "_"),
                label  = fn.name or "?",
            }
        end
        parts[#parts + 1] = theme.quicknav(navitems)

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
    local sidebar   = build_sidebar(corpus, nil)
    local total_fns = 0
    for _, fr in ipairs(corpus) do total_fns = total_fns + #fr.functions end

    -- Default categories — modules not matched go to "Utilities"
    local cat_order  = { "Model", "Context", "Vocab", "Sampler",
                         "AST", "From", "Runtime", "Dev", "Utilities" }
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
        if     name:match("^model")                               then cat = "Model"
        elseif name:match("^context")                             then cat = "Context"
        elseif name == "vocab"                                    then cat = "Vocab"
        elseif name:match("^sampler") or name == "custom_sampler" then cat = "Sampler"
        elseif name:match("^ast")                                 then cat = "AST"
        elseif name:match("^from")                                then cat = "From"
        elseif name:match("^runtime")                             then cat = "Runtime"
        elseif name:match("^dev")                                 then cat = "Dev"
        else                                                           cat = "Utilities"
        end
        cat_groups[cat][#cat_groups[cat] + 1] = entry
    end

    -- Remove empty categories from display order
    local visible_order = {}
    for _, c in ipairs(cat_order) do
        if #cat_groups[c] > 0 then visible_order[#visible_order + 1] = c end
    end

    local parts = {}
    parts[#parts + 1] = theme.html_open(_cfg.label .. " — API Reference")
    parts[#parts + 1] = theme.layout_open(sidebar,
        '<span class="text-zinc-500">' .. _cfg.label .. '</span>')
    parts[#parts + 1] = theme.api_index(#corpus, total_fns, visible_order, cat_groups, _cfg.label, _cfg.desc)
    parts[#parts + 1] = theme.layout_close()
    parts[#parts + 1] = theme.html_close()

    write_file(out_dir .. "/index.html", table.concat(parts))
end

-- ── Search index ──────────────────────────────────────────────────────────────

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
    local html = theme.landing_page(corpus, _cfg.id)
    write_file(out_dir .. "/index.html", html)
end

-- ── Public API ────────────────────────────────────────────────────────────────

--- Render a documentation site for one module into out_dir (flat layout).
---
--- @param  corpus       table   From parser.parse_dir().
--- @param  out_dir      string  Output directory (created if needed).
--- @param  readme_path  string? Path to README.md to use as landing page.
--- @param  opts         table?
---   opts.label   string?  Human name ("ion7-core", "ion7-grammar").
---   opts.id      string?  Short id ("core", "grammar") for cross-links.
---   opts.prefix  string?  Lua pattern stripped from module names.
function renderer.render(corpus, out_dir, readme_path, opts)
    -- Apply per-render config
    opts = opts or {}
    _cfg.label  = opts.label  or "ion7-core"
    _cfg.id     = opts.id     or "core"
    _cfg.prefix = opts.prefix or "ion7%.core%.?"
    _cfg.desc   = opts.desc   or ""

    out_dir = out_dir:gsub("/$", "")
    os.execute('mkdir -p "' .. out_dir .. '"')

    write_search_index(corpus, out_dir)
    render_index(corpus, out_dir)
    for _, fr in ipairs(corpus) do
        local out = render_module_page(fr, corpus, out_dir)
        io.write("[ion7-doc] " .. out .. "\n")
    end

    io.write("[ion7-doc] api index → " .. out_dir .. "/index.html\n")
end

--- Generate the root portal page (docs/index.html) linking all modules.
--- Called by gendoc in "all" mode; writes directly to out_dir/index.html.
---
--- @param  out_dir  string  Root docs directory (e.g. "docs/").
--- @param  corpus   table?  Combined corpus from all modules (for function count).
function renderer.render_portal(out_dir, corpus)
    out_dir = out_dir:gsub("/$", "")
    local html = theme.landing_page(corpus or {}, nil)   -- module_id=nil → portal mode
    write_file(out_dir .. "/index.html", html)
    io.write("[ion7-doc] portal   → " .. out_dir .. "/index.html\n")
end

--- Generate the API overview page (docs/api.html).
--- Lists all modules — available (clickable), in development, and planned.
---
--- @param  out_dir  string  Root docs directory (e.g. "docs/").
--- @param  corpus   table?  Combined corpus — used for function count display.
function renderer.render_api(out_dir, corpus)
    out_dir = out_dir:gsub("/$", "")
    local html = theme.api_overview_page(corpus or {})
    write_file(out_dir .. "/api.html", html)
    io.write("[ion7-doc] api      → " .. out_dir .. "/api.html\n")
end

--- Generate a standalone landing page (README-based) for the given module.
--- Used by gendoc when building a single module; not used in "all" mode
--- since the root docs/index.html acts as the portal.
---
--- @param  corpus      table
--- @param  out_dir     string
--- @param  opts        table?  Same as renderer.render opts.
function renderer.render_landing(corpus, out_dir, opts)
    opts = opts or {}
    _cfg.label  = opts.label  or "ion7-core"
    _cfg.id     = opts.id     or "core"
    _cfg.prefix = opts.prefix or "ion7%.core%.?"
    _cfg.desc   = opts.desc   or ""
    render_landing(corpus, out_dir)
    io.write("[ion7-doc] landing  → " .. out_dir .. "/index.html\n")
end

return renderer
