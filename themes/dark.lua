--- ion7-doc dark theme — monochrome professional

local theme = {}

-- ── Head ──────────────────────────────────────────────────────────────────────

function theme.html_open(title)
    return string.format([[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>%s &mdash; ion7 docs</title>
  <script>
    tailwind = { config: {
      theme: {
        extend: {
          fontFamily: {
            mono: ["'JetBrains Mono'", "'Fira Code'", "ui-monospace", "monospace"],
            sans: ["'Inter'", "system-ui", "sans-serif"],
          }
        }
      }
    }}
  </script>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    html { background: #09090b; }
    ::-webkit-scrollbar { width: 5px; height: 5px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #27272a; border-radius: 99px; }
    ::-webkit-scrollbar-thumb:hover { background: #3f3f46; }
    .fn-divider { border-top: 1px solid #1c1c1e; margin: 2rem 0; }
  </style>
</head>
<body class="bg-zinc-950 text-zinc-300 font-sans antialiased min-h-screen">
]], title)
end

function theme.html_close()
    return [[
<script>
(function() {
  var input = document.getElementById('search-input');
  var box   = document.getElementById('search-results');
  if (!input || !box) return;

  var index = null;

  fetch('search-index.json')
    .then(function(r) { return r.json(); })
    .then(function(data) { index = data; })
    .catch(function() {});

  input.addEventListener('input', function() {
    var q = input.value.trim().toLowerCase();
    if (!index || q.length < 2) { box.classList.add('hidden'); return; }

    var results = [];
    for (var i = 0; i < index.length; i++) {
      var item = index[i];
      if (item.name.toLowerCase().indexOf(q) !== -1 ||
          (item.desc && item.desc.toLowerCase().indexOf(q) !== -1)) {
        results.push(item);
        if (results.length >= 12) break;
      }
    }

    if (results.length === 0) { box.classList.add('hidden'); return; }

    var html = '';
    for (var j = 0; j < results.length; j++) {
      var r = results[j];
      var hl = r.name.replace(new RegExp('(' + q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')', 'gi'),
               '<span class="text-zinc-100">$1</span>');
      html += '<a href="' + r.href + '" class="flex items-baseline gap-3 px-3 py-2 hover:bg-zinc-800 border-b border-zinc-800/60 last:border-0 transition-colors">'
            + '<span class="font-mono text-zinc-300 text-xs shrink-0">' + hl + '</span>'
            + '<span class="text-zinc-600 text-xs truncate">' + (r.module || '') + '</span>'
            + '</a>';
    }
    box.innerHTML = html;
    box.classList.remove('hidden');
  });

  document.addEventListener('click', function(e) {
    if (!document.getElementById('search-container').contains(e.target)) {
      box.classList.add('hidden');
    }
  });

  input.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') { box.classList.add('hidden'); input.blur(); }
  });
})();
</script>
</body>
</html>
]]
end

-- ── Layout ────────────────────────────────────────────────────────────────────

function theme.layout_open(sidebar_html, breadcrumb_html)
    return string.format([[
<div class="flex min-h-screen">

  <!-- Sidebar -->
  <aside class="w-56 shrink-0 bg-zinc-950 border-r border-zinc-800/50 hidden lg:flex flex-col sticky top-0 h-screen overflow-y-auto">
    <div class="px-4 py-4 border-b border-zinc-800/50">
      <a href="index.html" class="flex items-center gap-1.5 group">
        <span class="text-zinc-100 font-mono font-semibold text-sm">ion7</span>
        <span class="text-zinc-700 font-mono text-sm">/</span>
        <span class="text-zinc-600 font-mono text-sm">docs</span>
      </a>
    </div>
    <nav class="flex-1 py-3 overflow-y-auto">
      %s
    </nav>
    <div class="px-4 py-3 border-t border-zinc-800/50 flex items-center justify-between">
      <span class="text-zinc-700 text-xs font-mono">v1.2.0</span>
      <a href="../" class="text-zinc-800 hover:text-zinc-500 text-xs font-mono transition-colors">&larr; home</a>
    </div>
  </aside>

  <!-- Content -->
  <div class="flex-1 min-w-0 flex flex-col">
    <header class="sticky top-0 z-10 bg-zinc-950/80 backdrop-blur border-b border-zinc-800/50 px-6 py-2 flex items-center gap-4">
      <div class="flex items-center gap-2 text-xs font-mono text-zinc-600 shrink-0">
        %s
      </div>
      <!-- Search -->
      <div class="flex-1 max-w-xs relative" id="search-container">
        <input id="search-input" type="text" placeholder="Search functions..."
          autocomplete="off" spellcheck="false"
          class="w-full bg-zinc-900/80 border border-zinc-800 hover:border-zinc-700 focus:border-zinc-600 rounded px-3 py-1.5 text-xs font-mono text-zinc-300 placeholder-zinc-700 outline-none transition-colors" />
        <div id="search-results"
          class="hidden absolute top-full left-0 right-0 mt-1 bg-zinc-900 border border-zinc-800 rounded-lg shadow-xl overflow-hidden z-50 max-h-72 overflow-y-auto">
        </div>
      </div>
    </header>
    <main class="flex-1 px-8 md:px-14 py-10 max-w-3xl w-full">
]], sidebar_html, breadcrumb_html or "")
end

function theme.layout_close()
    return "    </main>\n  </div>\n</div>\n"
end

-- ── Sidebar ───────────────────────────────────────────────────────────────────

function theme.sidebar_section(label, items_html)
    return string.format([[
<div class="mb-5 px-2">
  <p class="text-zinc-700 text-xs font-mono uppercase tracking-widest mb-1.5 px-2">%s</p>
  <ul class="space-y-px">%s</ul>
</div>]], label, items_html)
end

function theme.sidebar_link(href, label, active)
    if active then
        return string.format(
            '<li><a href="%s" class="block px-2 py-1.5 rounded text-zinc-100 bg-zinc-800/80 text-xs font-mono">%s</a></li>',
            href, label)
    end
    return string.format(
        '<li><a href="%s" class="block px-2 py-1.5 rounded text-zinc-500 hover:text-zinc-200 hover:bg-zinc-800/40 text-xs font-mono transition-colors">%s</a></li>',
        href, label)
end

-- ── Breadcrumb ────────────────────────────────────────────────────────────────

function theme.breadcrumb(parts)
    local html = {}
    for i, p in ipairs(parts) do
        if i > 1 then
            html[#html + 1] = '<span class="text-zinc-800">/</span>'
        end
        if p.href then
            html[#html + 1] = string.format(
                '<a href="%s" class="hover:text-zinc-400 transition-colors">%s</a>', p.href, p.label)
        else
            html[#html + 1] = string.format('<span class="text-zinc-500">%s</span>', p.label)
        end
    end
    return table.concat(html, " ")
end

-- ── Page header ───────────────────────────────────────────────────────────────

function theme.page_header(kind_label, name, description)
    local parts = {}
    parts[#parts + 1] = string.format(
        '<p class="text-zinc-700 text-xs font-mono uppercase tracking-widest mb-4">%s</p>\n',
        kind_label)
    parts[#parts + 1] = string.format(
        '<h1 class="text-3xl font-semibold text-zinc-100 tracking-tight mb-4 font-mono">%s</h1>\n',
        name)
    if description and description ~= "" then
        parts[#parts + 1] = string.format(
            '<p class="text-zinc-500 text-sm leading-relaxed mb-10 max-w-2xl pb-8 border-b border-zinc-800/50">%s</p>\n',
            description)
    end
    return table.concat(parts)
end

function theme.section_title(text)
    return string.format(
        '<p class="text-zinc-600 text-xs font-mono uppercase tracking-widest mt-10 mb-6">%s</p>\n',
        text)
end

function theme.p(text)
    return string.format(
        '<p class="text-zinc-400 text-sm leading-relaxed mb-3">%s</p>\n', text)
end

-- ── Quick-nav pills ───────────────────────────────────────────────────────────

function theme.quicknav(items)
    -- items = { {anchor, label}, ... }
    local parts = { '<div class="flex flex-wrap gap-1.5 mb-8 pb-6 border-b border-zinc-800/50">\n' }
    for _, it in ipairs(items) do
        parts[#parts + 1] = string.format(
            '<a href="#%s" class="font-mono text-xs text-zinc-500 hover:text-zinc-300 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 hover:border-zinc-700 px-2.5 py-1 rounded transition-all">%s</a>\n',
            it.anchor, it.label)
    end
    parts[#parts + 1] = '</div>\n'
    return table.concat(parts)
end

-- ── Fields block (for @class) ─────────────────────────────────────────────────

function theme.fields_block(tags)
    local rows = {}
    for _, t in ipairs(tags) do
        if t.tag == "field" then rows[#rows + 1] = t end
    end
    if #rows == 0 then return "" end

    local parts = {}
    parts[#parts + 1] = '<div class="mb-8 bg-zinc-900/50 border border-zinc-800/60 rounded-lg overflow-hidden">\n'
    for _, t in ipairs(rows) do
        parts[#parts + 1] = string.format([[
<div class="flex items-baseline gap-0 px-4 py-2.5 border-b border-zinc-800/40 last:border-0">
  <span class="font-mono text-zinc-300 text-xs w-40 shrink-0">%s</span>
  <span class="font-mono text-zinc-600 text-xs w-28 shrink-0">%s</span>
  <span class="text-zinc-600 text-xs">%s</span>
</div>
]], t.name or "?", t.type or "", t.desc or "")
    end
    parts[#parts + 1] = '</div>\n'
    return table.concat(parts)
end

-- ── Usage block ───────────────────────────────────────────────────────────────

function theme.usage_block(lines)
    if not lines or #lines == 0 then return "" end
    local escaped = {}
    for _, l in ipairs(lines) do
        escaped[#escaped + 1] = l
            :gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    end
    -- strip trailing blank lines
    while escaped[#escaped] == "" do table.remove(escaped) end
    return string.format(
        '<pre class="bg-zinc-900 border border-zinc-800 rounded-lg px-5 py-4 text-xs font-mono text-zinc-300 overflow-x-auto leading-relaxed mb-6"><code>%s</code></pre>\n',
        table.concat(escaped, "\n"))
end

-- ── Function card ─────────────────────────────────────────────────────────────
--
-- Structure:
--   ### function_name          ← name as heading
--   description                ← short description
--                              ← blank line
--   function call block        ← monospace call signature
--   params row × n             ← name | type | desc
--   returns row                ← type | desc
--   example block?             ← code example if @usage present
--   raises note?               ← if @error present
--   ---                        ← divider before next fn

function theme.fn_card(item)
    local anchor = (item.name or "fn"):gsub("[^%w_]", "_")
    local sig_params = ""
    if item.signature then
        sig_params = item.signature:match("%((.-)%)") or ""
    end

    local parts = {}
    parts[#parts + 1] = string.format('<div id="%s" class="scroll-mt-20">\n', anchor)

    -- ### function_name
    parts[#parts + 1] = string.format(
        '<h3 class="text-sm font-mono font-semibold text-zinc-100 mb-2 tracking-tight">%s</h3>\n',
        item.name or "?")

    -- description
    if item.description and item.description ~= "" then
        parts[#parts + 1] = string.format(
            '<p class="text-zinc-400 text-sm leading-relaxed mb-4">%s</p>\n',
            item.description)
    end

    -- call block
    parts[#parts + 1] = string.format(
        '<div class="font-mono text-xs bg-zinc-900/80 border border-zinc-800/60 rounded-md px-4 py-3 mb-5 overflow-x-auto">'
        .. '<span class="text-zinc-500">%s</span>'
        .. '<span class="text-zinc-700">(</span>'
        .. '<span class="text-zinc-500">%s</span>'
        .. '<span class="text-zinc-700">)</span>'
        .. '</div>\n',
        item.name or "?",
        sig_params)

    -- params
    local params = {}
    for _, t in ipairs(item.tags) do
        if t.tag == "param" then params[#params + 1] = t end
    end
    if #params > 0 then
        parts[#parts + 1] = '<div class="mb-5 border border-zinc-800/40 rounded-md overflow-hidden text-xs">\n'
        for _, t in ipairs(params) do
            parts[#parts + 1] = string.format(
                '<div class="flex items-baseline gap-0 px-4 py-2 border-b border-zinc-800/30 last:border-0 bg-zinc-900/30">'
                .. '<span class="font-mono text-zinc-300 w-36 shrink-0">%s</span>'
                .. '<span class="font-mono text-zinc-700 w-28 shrink-0">%s</span>'
                .. '<span class="text-zinc-500">%s</span>'
                .. '</div>\n',
                t.name or "?", t.type or "", t.desc or "")
        end
        parts[#parts + 1] = '</div>\n'
    end

    -- returns
    local returns = {}
    for _, t in ipairs(item.tags) do
        if t.tag == "return" then returns[#returns + 1] = t end
    end
    if #returns > 0 then
        parts[#parts + 1] = '<div class="mb-5 border border-zinc-800/40 rounded-md overflow-hidden text-xs">\n'
        for _, t in ipairs(returns) do
            parts[#parts + 1] = string.format(
                '<div class="flex items-baseline gap-0 px-4 py-2 border-b border-zinc-800/30 last:border-0 bg-zinc-900/20">'
                .. '<span class="font-mono text-zinc-600 w-36 shrink-0">&rarr;&nbsp;%s</span>'
                .. '<span class="text-zinc-500 w-28 shrink-0"></span>'
                .. '<span class="text-zinc-500">%s</span>'
                .. '</div>\n',
                t.type or "?", t.desc or "")
        end
        parts[#parts + 1] = '</div>\n'
    end

    -- usage example
    for _, t in ipairs(item.tags) do
        if t.tag == "usage" and t.lines and #t.lines > 0 then
            parts[#parts + 1] = theme.usage_block(t.lines)
        end
    end

    -- raises
    for _, t in ipairs(item.tags) do
        if t.tag == "error" then
            parts[#parts + 1] = string.format(
                '<p class="text-xs font-mono text-zinc-700 mt-1 mb-3">raises &mdash; %s</p>\n',
                t.desc or "")
        end
    end

    parts[#parts + 1] = '</div>\n'
    return table.concat(parts)
end

-- ── API index homepage ────────────────────────────────────────────────────────
--
-- cat_order  : array of category name strings
-- cat_groups : { [cat] = { {href, display, n_fns, desc}, ... }, ... }

function theme.api_index(n_modules, n_fns, cat_order, cat_groups, label, desc)
    label = label or "ion7-core"
    desc  = desc  or "LuaJIT FFI bindings for llama.cpp. Direct calls into libllama.so — no subprocess, no HTTP, no allocations per token."
    local parts = {}

    -- Header
    parts[#parts + 1] = string.format([[
<p class="text-zinc-700 text-xs font-mono uppercase tracking-widest mb-1">%s</p>
<h1 class="text-2xl font-semibold text-zinc-100 tracking-tight mb-2 font-mono">API Reference</h1>
<p class="text-zinc-600 text-sm leading-relaxed mb-8 max-w-lg">%s</p>
<div class="flex gap-6 pb-8 mb-8 border-b border-zinc-800/50">
  <div>
    <span class="font-mono text-zinc-200 text-base font-semibold">%d</span>
    <span class="font-mono text-zinc-700 text-xs ml-1.5">modules</span>
  </div>
  <div>
    <span class="font-mono text-zinc-200 text-base font-semibold">%d</span>
    <span class="font-mono text-zinc-700 text-xs ml-1.5">documented functions</span>
  </div>
</div>
]], label, desc, n_modules, n_fns)

    -- Category groups
    for _, cat in ipairs(cat_order) do
        local entries = cat_groups[cat]
        if entries and #entries > 0 then
            parts[#parts + 1] = string.format(
                '<p class="text-zinc-600 text-xs font-mono uppercase tracking-widest mt-8 mb-3">%s</p>\n'
                .. '<div class="grid grid-cols-1 sm:grid-cols-2 gap-1.5">\n',
                cat)
            for _, e in ipairs(entries) do
                parts[#parts + 1] = string.format(
                    '<a href="%s" class="group flex items-baseline justify-between '
                    .. 'bg-zinc-900/40 hover:bg-zinc-900 border border-zinc-800/40 hover:border-zinc-700 '
                    .. 'rounded px-4 py-2.5 transition-all min-w-0">\n'
                    .. '  <div class="flex items-baseline gap-3 min-w-0">\n'
                    .. '    <span class="font-mono text-zinc-300 group-hover:text-zinc-100 text-xs font-medium shrink-0 transition-colors">%s</span>\n'
                    .. '    <span class="text-zinc-700 text-xs truncate hidden sm:block">%s</span>\n'
                    .. '  </div>\n'
                    .. '  <span class="font-mono text-zinc-800 group-hover:text-zinc-600 text-xs shrink-0 ml-3 transition-colors">%d fn</span>\n'
                    .. '</a>\n',
                    e.href, e.display, e.desc, e.n_fns)
            end
            parts[#parts + 1] = '</div>\n'
        end
    end

    return table.concat(parts)
end

-- ── Landing page ─────────────────────────────────────────────────────────────

function theme.landing_page(corpus, module_id)
    -- Count total documented functions across the corpus
    local total_fns = 0
    for _, fr in ipairs(corpus) do
        total_fns = total_fns + #fr.functions
    end

    -- Code example (escaped for HTML)
    local code = [[local Model   = require "ion7.core.model"
local Sampler = require "ion7.core.sampler"

local model = Model.load("model.gguf", { n_gpu_layers = -1 })
local ctx   = model:context({ n_ctx = 4096 })
local vocab = model:vocab()
local samp  = Sampler.chain(vocab):temp(0.8):top_p(0.95):build()

local tokens, n = vocab:tokenize("Hello, world!", true)
ctx:decode(tokens, n)

repeat
    local token = samp:sample(ctx, -1)
    samp:accept(token)
    io.write(vocab:piece(token))
until vocab:is_eog(token)]]
    code = code:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")

    -- Cross-module hrefs:
    --   nil (portal, docs/index.html)  → core/, grammar/, llm/ (relative to docs/)
    --   "core"    (docs/core/)         → grammar → ../grammar/, llm → ../llm/
    --   "grammar" (docs/grammar/)      → core    → ../core/,    llm → ../llm/
    --   "llm"     (docs/llm/)          → core    → ../core/,    grammar → ../grammar/
    local core_href, grammar_href, llm_href
    if     module_id == nil       then core_href = "core/";     grammar_href = "grammar/";   llm_href = "llm/"
    elseif module_id == "grammar" then core_href = "../core/";                                llm_href = "../llm/"
    elseif module_id == "core"    then                           grammar_href = "../grammar/"; llm_href = "../llm/"
    elseif module_id == "llm"     then core_href = "../core/";  grammar_href = "../grammar/"
    end

    -- Module cards
    local modules = {
        {
            name   = "ion7-core",
            status = "stable v1.1",
            desc   = "LuaJIT FFI &rarr; llama.cpp. Zero malloc per token. 84 bridge functions, 4 translation units.",
            href   = core_href,
        },
        {
            name   = "ion7-grammar",
            status = "beta v0.2",
            desc   = "Grammar engine for LuaJIT. Compiles regex, ABNF, EBNF, JSON Schema, Lua type annotations to GBNF. Per-seq Backtrack + DCCD runtime, pure-Lua fuzzer, format auto-detect.",
            href   = grammar_href,
        },
        {
            name   = "ion7-llm",
            status = "beta v0.2",
            desc   = "Chat pipeline + multi-session inference. Per-seq KV snapshots, prefix cache, three-channel streaming, schema-constrained sampling, interleaved-thinking tool loop.",
            href   = llm_href,
        },
        {
            name   = "ion7-engram",
            status = "research",
            desc   = "Sparse Autoencoder on LLM embeddings. Superposition hypothesis, 0.91 cosine reconstruction.",
        },
        {
            name   = "ion7-flow",
            status = "PoC",
            desc   = "Visual node editor. React Flow &plus; Bun WebSocket &plus; LuaJIT executor.",
        },
        {
            name   = "ion7-nvim",
            status = "plugin",
            desc   = "Neovim integration. Subprocess-based streaming token generation.",
        },
        {
            name   = "ion7-embed",
            status = "planned",
            desc   = "Local embeddings without llama-server. Cosine similarity, pooling, batch encoding.",
        },
        {
            name   = "ion7-memory",
            status = "planned",
            desc   = "3-layer persistent memory: hot index &plus; topics &plus; session archives.",
        },
        {
            name   = "ion7-rag",
            status = "planned",
            desc   = "SQLite &plus; vector search. Query &rarr; embed &rarr; retrieve pipeline.",
        },
    }

    local cards = {}
    for _, m in ipairs(modules) do
        if m.href then
            cards[#cards + 1] = string.format(
                '<a href="%s" class="group flex flex-col bg-zinc-900/50 hover:bg-zinc-900 border border-zinc-800/60 hover:border-zinc-700 rounded-lg px-5 py-4 transition-all">\n'
                .. '  <div class="flex items-baseline justify-between mb-2">\n'
                .. '    <span class="font-mono text-zinc-200 group-hover:text-zinc-100 text-sm font-medium transition-colors">%s</span>\n'
                .. '    <span class="font-mono text-zinc-500 text-xs">%s</span>\n'
                .. '  </div>\n'
                .. '  <p class="text-zinc-600 text-xs leading-relaxed flex-1">%s</p>\n'
                .. '  <span class="font-mono text-zinc-600 group-hover:text-zinc-400 text-xs mt-3 transition-colors">API Reference &rarr;</span>\n'
                .. '</a>',
                m.href, m.name, m.status, m.desc)
        else
            local dim = m.status == "planned"
            local name_c  = dim and "text-zinc-700"  or "text-zinc-500"
            local badge_c = dim and "text-zinc-800"  or "text-zinc-700"
            local desc_c  = dim and "text-zinc-800"  or "text-zinc-700"
            local border  = dim and "border-zinc-800/20 bg-zinc-900/10" or "border-zinc-800/30 bg-zinc-900/20"
            cards[#cards + 1] = string.format(
                '<div class="flex flex-col border %s rounded-lg px-5 py-4">\n'
                .. '  <div class="flex items-baseline justify-between mb-2">\n'
                .. '    <span class="font-mono %s text-sm font-medium">%s</span>\n'
                .. '    <span class="font-mono %s text-xs">%s</span>\n'
                .. '  </div>\n'
                .. '  <p class="%s text-xs leading-relaxed">%s</p>\n'
                .. '</div>',
                border, name_c, m.name, badge_c, m.status, desc_c, m.desc)
        end
    end

    local parts = {}

    -- ── Head ──────────────────────────────────────────────────────────────────
    parts[#parts + 1] = [[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ion7-labs &mdash; LuaJIT &times; llama.cpp</title>
  <script>
    tailwind = { config: {
      theme: {
        extend: {
          fontFamily: {
            mono: ["'JetBrains Mono'", "'Fira Code'", "ui-monospace", "monospace"],
            sans: ["'Inter'", "system-ui", "sans-serif"],
          }
        }
      }
    }}
  </script>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    html { background: #09090b; }
    ::-webkit-scrollbar { width: 5px; height: 5px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #27272a; border-radius: 99px; }
    ::-webkit-scrollbar-thumb:hover { background: #3f3f46; }
    .hero-dots {
      background-image: radial-gradient(circle, rgba(63,63,70,0.45) 1px, transparent 1px);
      background-size: 28px 28px;
    }
  </style>
</head>
<body class="bg-zinc-950 text-zinc-300 font-sans antialiased">
]]

    -- ── Nav ───────────────────────────────────────────────────────────────────
    parts[#parts + 1] = [[
<header class="border-b border-zinc-800/40 px-6 md:px-14 py-4">
  <div class="max-w-5xl mx-auto flex items-center justify-between">
    <a href="." class="flex items-center gap-1.5">
      <span class="font-mono font-semibold text-zinc-100 text-sm">ion7</span>
      <span class="font-mono text-zinc-700 text-sm">/</span>
      <span class="font-mono text-zinc-600 text-sm">labs</span>
    </a>
    <nav class="flex items-center gap-6">
      <a href="api.html" class="font-mono text-xs text-zinc-500 hover:text-zinc-300 transition-colors">api</a>
      <a href="https://github.com/ion7-labs" class="font-mono text-xs text-zinc-500 hover:text-zinc-300 transition-colors">github &nearr;</a>
    </nav>
  </div>
</header>
]]

    -- ── Hero ──────────────────────────────────────────────────────────────────
    parts[#parts + 1] = [[
<section class="hero-dots relative">
  <div class="max-w-5xl mx-auto px-6 md:px-14 pt-28 pb-24 relative">
    <p class="font-mono text-xs text-zinc-700 uppercase tracking-[0.2em] mb-6">ion7-labs</p>
    <h1 class="text-5xl md:text-7xl font-mono font-semibold text-zinc-100 leading-none mb-7 tracking-tight">
      LuaJIT<br><span class="text-zinc-600">&times;</span> llama.cpp
    </h1>
    <p class="text-zinc-500 text-base leading-relaxed mb-10 max-w-xl">
      Local LLM inference runtime for LuaJIT.<br>
      Direct FFI into libllama.so &mdash; microseconds, not milliseconds.
    </p>
    <div class="flex flex-wrap gap-3">
      <a href="api.html" class="font-mono text-sm bg-zinc-100 text-zinc-950 hover:bg-white px-6 py-3 rounded transition-colors font-medium">
        API Overview &rarr;
      </a>
      <a href="https://github.com/ion7-labs" class="font-mono text-sm border border-zinc-800 hover:border-zinc-700 text-zinc-500 hover:text-zinc-200 px-6 py-3 rounded transition-colors">
        GitHub &nearr;
      </a>
    </div>
  </div>
</section>
]]

    -- ── Stats strip ───────────────────────────────────────────────────────────
    parts[#parts + 1] = string.format([[
<div class="border-y border-zinc-800/40 bg-zinc-900/20">
  <div class="max-w-5xl mx-auto px-6 md:px-14 py-8 grid grid-cols-2 md:grid-cols-4 gap-8">
    <div>
      <p class="font-mono text-2xl font-semibold text-zinc-100">0</p>
      <p class="font-mono text-xs text-zinc-600 mt-1">Python</p>
    </div>
    <div>
      <p class="font-mono text-2xl font-semibold text-zinc-100">0</p>
      <p class="font-mono text-xs text-zinc-600 mt-1">malloc / token</p>
    </div>
    <div>
      <p class="font-mono text-2xl font-semibold text-zinc-100">0</p>
      <p class="font-mono text-xs text-zinc-600 mt-1">http overhead</p>
    </div>
    <div>
      <p class="font-mono text-2xl font-semibold text-zinc-100">%d</p>
      <p class="font-mono text-xs text-zinc-600 mt-1">documented functions</p>
    </div>
  </div>
</div>
]], total_fns)

    -- ── Features ──────────────────────────────────────────────────────────────
    parts[#parts + 1] = [[
<section class="max-w-5xl mx-auto px-6 md:px-14 py-16">
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-px bg-zinc-800/30 rounded-xl overflow-hidden border border-zinc-800/30">
    <div class="bg-zinc-950 px-6 py-6">
      <p class="font-mono text-zinc-300 text-xs font-medium mb-2">zero malloc / token</p>
      <p class="text-zinc-600 text-xs leading-relaxed">llama_batch pre-allocated at context creation. KV cache managed, never reallocated. Every generated token is a pure compute step.</p>
    </div>
    <div class="bg-zinc-950 px-6 py-6">
      <p class="font-mono text-zinc-300 text-xs font-medium mb-2">direct FFI</p>
      <p class="text-zinc-600 text-xs leading-relaxed">No subprocess, no HTTP, no JSON serialization. LuaJIT ffi.call() straight into libllama.so — call overhead in microseconds.</p>
    </div>
    <div class="bg-zinc-950 px-6 py-6">
      <p class="font-mono text-zinc-300 text-xs font-medium mb-2">full llama.cpp surface</p>
      <p class="text-zinc-600 text-xs leading-relaxed">84 bridge functions across 4 translation units. Chat templates (Jinja2), LoRA, speculative decoding, grammar, reasoning budget — all exposed.</p>
    </div>
    <div class="bg-zinc-950 px-6 py-6">
      <p class="font-mono text-zinc-300 text-xs font-medium mb-2">grammar engine</p>
      <p class="text-zinc-600 text-xs leading-relaxed">GBNF, JSON Schema, regex, tool calling in pure Lua. CRANE-style lazy grammar activation. Constrained generation without sacrificing reasoning.</p>
    </div>
  </div>
</section>
]]

    -- ── Code example ──────────────────────────────────────────────────────────
    parts[#parts + 1] = string.format([[
<section class="max-w-5xl mx-auto px-6 md:px-14 pb-20">
  <p class="font-mono text-xs text-zinc-700 uppercase tracking-widest mb-6">Quick start</p>
  <pre class="bg-zinc-900/60 border border-zinc-800/60 rounded-lg px-6 py-5 text-xs font-mono text-zinc-400 overflow-x-auto leading-relaxed"><code>%s</code></pre>
</section>
]], code)

    -- ── Modules grid ──────────────────────────────────────────────────────────
    parts[#parts + 1] = string.format([[
<section class="max-w-5xl mx-auto px-6 md:px-14 pb-24">
  <p class="font-mono text-xs text-zinc-700 uppercase tracking-widest mb-6">Stack</p>
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
%s
  </div>
</section>
]], table.concat(cards, "\n"))

    -- ── Footer ────────────────────────────────────────────────────────────────
    parts[#parts + 1] = [[
<footer class="border-t border-zinc-800/40 px-6 md:px-14 py-8">
  <div class="max-w-5xl mx-auto flex items-center justify-between">
    <span class="font-mono text-zinc-800 text-xs">ion7-labs &mdash; 2026</span>
    <a href="api.html" class="font-mono text-zinc-700 hover:text-zinc-500 text-xs transition-colors">API Overview &rarr;</a>
  </div>
</footer>

</body>
</html>
]]

    return table.concat(parts)
end

-- ── API Overview page ─────────────────────────────────────────────────────────
--
-- Standalone page (no sidebar) listing every module with status, description,
-- and a link to the API reference when docs exist.
--
-- corpus : table from parser.parse_dir() — used only for function counts.

function theme.api_overview_page(corpus)
    -- Count documented functions across the corpus
    local total_fns = 0
    for _, fr in ipairs(corpus or {}) do
        total_fns = total_fns + #fr.functions
    end

    -- ── Module registry ───────────────────────────────────────────────────────
    -- Groups: "available" | "dev" | "planned"
    local modules = {
        -- ── Available — docs generated, clickable ────────────────────────────
        {
            name   = "ion7-core",
            status = "stable v1.2.0",
            group  = "available",
            href   = "core/",
            tags   = {"FFI", "llama.cpp", "zero-malloc"},
            desc   = "LuaJIT FFI &rarr; libllama.so. 84 bridge functions across 4 translation units: model, context, KV cache, speculative decoding, chat templates (Jinja2), sampling, LoRA, reasoning budget, grammar constraints.",
            detail = "Zero malloc per generated token. KV snapshot/restore. Prefix cache. Full libcommon surface (DRY, XTC, EAGLE3, NGRAM_CACHE).",
        },
        {
            name   = "ion7-grammar",
            status = "beta v0.2",
            group  = "available",
            href   = "grammar/",
            tags   = {"GBNF", "ABNF", "EBNF", "JSON Schema", "LPeg"},
            desc   = "Grammar engine for LuaJIT. Eight input formats (regex / ABNF / EBNF / JSON Schema / type DSL / enum / tool / auto-detect) all yielding the same composable Grammar_obj.",
            detail = "AST + LPeg-backed parsers. Per-seq Backtrack and DCCD (multi-tenant safe). GrammarContext for stateful SQL agents. Pure-Lua fuzzer. Composition algebra (union, sequence, wrap, interleave).",
        },
        {
            name   = "ion7-llm",
            status = "beta v0.2",
            group  = "available",
            href   = "llm/",
            tags   = {"chat", "multi-session", "RadixAttention", "streaming"},
            desc   = "Chat pipeline + multi-session inference orchestration. Per-seq KV snapshots, prefix cache, slot pool, fork. Engine + Pool (~6&times; aggregate speedup).",
            detail = "Mid-generation eviction, RadixAttention exact-match prefix cache, Y-Token sink hook. 4-channel streaming (content/thinking/tool_call_delta/tool_call_done/stop). Format-aware tool extraction (OpenAI/Qwen/Mistral/Hermes). Interleaved-thinking tool loop. Reasoning budget. Embeddings.",
        },
        -- ── In Development — no docs link yet ───────────────────────────────
        {
            name   = "ion7-engram",
            status = "research",
            group  = "dev",
            tags   = {"SAE", "superposition", "embeddings"},
            desc   = "Sparse Autoencoder on LLM embeddings. Validates superposition hypothesis: 0.91 cosine reconstruction, 0.500 Jaccard between related concept clusters.",
            detail = "SAE:edit() for primitive surgery (zero/set/scale). 64 primitives, K=16 active. Adam sparse, LuaJIT + OpenBLAS FFI. x16 embedding compression.",
        },
        {
            name   = "ion7-flow",
            status = "PoC",
            group  = "dev",
            tags   = {"visual", "React Flow", "Bun"},
            desc   = "Visual node editor for ion7 pipelines. React Flow + Bun WebSocket server + LuaJIT executor. Each ion7-core function is a wireable node.",
            detail = "Browser &leftrightarrow; Bun WS &leftrightarrow; LuaJIT. Topological execution. Nodes: Model_load, Ctx_decode, Sampler_chain, Generate, Display.",
        },
        {
            name   = "ion7-nvim",
            status = "plugin",
            group  = "dev",
            tags   = {"Neovim", "streaming"},
            desc   = "Neovim plugin for in-editor LLM generation. Subprocess-based streaming via jobstart(). Supports multi-turn via --msgs-file.",
            detail = "Protocol: TOKEN:<encoded> / DONE:<metrics> / ERROR:<msg> over stdout. No HTTP dependency.",
        },
        -- ── Planned ──────────────────────────────────────────────────────────
        {
            name   = "ion7-embed",
            status = "planned",
            group  = "planned",
            tags   = {"embeddings", "cosine", "pooling"},
            desc   = "Local embeddings without llama-server. Load Qwen3-Embedding-8B directly via ion7-core FFI — no HTTP, no subprocess.",
            detail = "Cosine similarity, mean/CLS pooling, batch encoding. Prerequisite for ion7-memory and ion7-rag.",
        },
        {
            name   = "ion7-memory",
            status = "planned",
            group  = "planned",
            tags   = {"memory", "3-layer", "RAG"},
            desc   = "3-layer persistent memory: hot index (always in context) &plus; topics (on-demand) &plus; session archives (grep only).",
            detail = "Layer 1: ~150 char pointers. Layer 2: thematic files loaded by semantic distance. Layer 3: transcript archives, grep-only retrieval.",
        },
        {
            name   = "ion7-rag",
            status = "planned",
            group  = "planned",
            tags   = {"SQLite", "vss", "retrieval"},
            desc   = "Retrieval-Augmented Generation pipeline. SQLite &plus; sqlite-vss vector store. Query &rarr; embed &rarr; cosine search &rarr; context injection.",
            detail = "Depends on ion7-embed. Semantic Pyramid Indexing (arXiv:2511.16681) — multi-resolution query-adaptive retrieval.",
        },
        {
            name   = "ion7-tts",
            status = "planned",
            group  = "planned",
            tags   = {"TTS", "Kokoro", "streaming"},
            desc   = "Local text-to-speech via Kokoro-82M FFI. Streaming token&rarr;audio pipeline for &lt;250ms first-sound latency in NPC AI pipelines.",
            detail = "Part of the STT &rarr; LLM &rarr; TTS NPC pipeline: ~250ms first sound. CPU inference, leaves GPU free for LLM.",
        },
        {
            name   = "ion7-stt",
            status = "planned",
            group  = "planned",
            tags   = {"STT", "Whisper", "streaming"},
            desc   = "Local speech-to-text via Whisper FFI. Streaming voice input with &lt;50ms segment latency.",
            detail = "Whisper tiny model, ~30-50ms. Feeds streaming text tokens directly to ion7-llm. GPU-accelerated on CUDA.",
        },
        {
            name   = "ion7-train",
            status = "planned",
            group  = "planned",
            tags   = {"LoRA", "QLoRA", "GGML autograd"},
            desc   = "Fine-tuning and distillation via GGML autograd. LoRA/QLoRA on RTX 3060. Teacher&rarr;student distillation. No Python.",
            detail = "AdamW + cosine warmup. Gradient accumulation. Dataset management. L-BFGS in Lua pur (Torch7-inspired). target: &lt;500M models in BF16.",
        },
    }

    -- Separate into groups
    local available, in_dev, planned = {}, {}, {}
    for _, m in ipairs(modules) do
        if     m.group == "available" then available[#available + 1] = m
        elseif m.group == "dev"       then in_dev[#in_dev + 1]       = m
        else                               planned[#planned + 1]      = m
        end
    end

    -- ── Card renderers ────────────────────────────────────────────────────────

    local function tag_pill(t)
        return string.format(
            '<span class="font-mono text-zinc-700 text-xs bg-zinc-900 border border-zinc-800/60 px-1.5 py-0.5 rounded">%s</span>',
            t)
    end

    local function tags_html(tags)
        if not tags or #tags == 0 then return "" end
        local p = {}
        for _, t in ipairs(tags) do p[#p + 1] = tag_pill(t) end
        return '<div class="flex flex-wrap gap-1 mb-3">' .. table.concat(p) .. '</div>'
    end

    -- Available card (bright, clickable)
    local function available_card(m)
        return string.format(
            '<a href="%s" class="group flex flex-col bg-zinc-900/50 hover:bg-zinc-900 border border-zinc-800/60 hover:border-zinc-600 rounded-lg px-5 py-5 transition-all">\n'
            .. '  <div class="flex items-baseline justify-between mb-3">\n'
            .. '    <span class="font-mono text-zinc-100 group-hover:text-white text-sm font-semibold transition-colors">%s</span>\n'
            .. '    <span class="font-mono text-zinc-500 text-xs border border-zinc-700/60 px-2 py-0.5 rounded">%s</span>\n'
            .. '  </div>\n'
            .. '  %s\n'
            .. '  <p class="text-zinc-500 text-xs leading-relaxed mb-3 flex-1">%s</p>\n'
            .. '  <p class="text-zinc-700 text-xs leading-relaxed mb-4">%s</p>\n'
            .. '  <span class="font-mono text-zinc-600 group-hover:text-zinc-300 text-xs transition-colors">API Reference &rarr;</span>\n'
            .. '</a>\n',
            m.href, m.name, m.status,
            tags_html(m.tags), m.desc, m.detail)
    end

    -- In-dev card (medium dim, no link)
    local function dev_card(m)
        return string.format(
            '<div class="flex flex-col border border-zinc-800/40 bg-zinc-900/20 rounded-lg px-5 py-5">\n'
            .. '  <div class="flex items-baseline justify-between mb-3">\n'
            .. '    <span class="font-mono text-zinc-400 text-sm font-medium">%s</span>\n'
            .. '    <span class="font-mono text-zinc-600 text-xs border border-zinc-800/40 px-2 py-0.5 rounded">%s</span>\n'
            .. '  </div>\n'
            .. '  %s\n'
            .. '  <p class="text-zinc-600 text-xs leading-relaxed mb-3 flex-1">%s</p>\n'
            .. '  <p class="text-zinc-700 text-xs leading-relaxed">%s</p>\n'
            .. '</div>\n',
            m.name, m.status,
            tags_html(m.tags), m.desc, m.detail)
    end

    -- Planned card (dim, no link)
    local function planned_card(m)
        return string.format(
            '<div class="flex flex-col border border-zinc-800/20 bg-zinc-900/10 rounded-lg px-5 py-4">\n'
            .. '  <div class="flex items-baseline justify-between mb-2">\n'
            .. '    <span class="font-mono text-zinc-600 text-sm font-medium">%s</span>\n'
            .. '    <span class="font-mono text-zinc-800 text-xs">%s</span>\n'
            .. '  </div>\n'
            .. '  %s\n'
            .. '  <p class="text-zinc-700 text-xs leading-relaxed">%s</p>\n'
            .. '</div>\n',
            m.name, m.status,
            tags_html(m.tags), m.desc)
    end

    -- ── Render ────────────────────────────────────────────────────────────────
    local parts = {}

    -- Head (same config as landing_page / html_open)
    parts[#parts + 1] = [[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>API Overview &mdash; ion7-labs</title>
  <script>
    tailwind = { config: {
      theme: {
        extend: {
          fontFamily: {
            mono: ["'JetBrains Mono'", "'Fira Code'", "ui-monospace", "monospace"],
            sans: ["'Inter'", "system-ui", "sans-serif"],
          }
        }
      }
    }}
  </script>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    html { background: #09090b; }
    ::-webkit-scrollbar { width: 5px; height: 5px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #27272a; border-radius: 99px; }
    ::-webkit-scrollbar-thumb:hover { background: #3f3f46; }
  </style>
</head>
<body class="bg-zinc-950 text-zinc-300 font-sans antialiased">
]]

    -- Nav
    parts[#parts + 1] = [[
<header class="border-b border-zinc-800/40 px-6 md:px-14 py-4 sticky top-0 bg-zinc-950/90 backdrop-blur z-10">
  <div class="max-w-5xl mx-auto flex items-center justify-between">
    <a href="index.html" class="flex items-center gap-1.5 group">
      <span class="font-mono font-semibold text-zinc-100 text-sm">ion7</span>
      <span class="font-mono text-zinc-700 text-sm">/</span>
      <span class="font-mono text-zinc-600 group-hover:text-zinc-400 text-sm transition-colors">labs</span>
    </a>
    <nav class="flex items-center gap-6">
      <a href="index.html" class="font-mono text-xs text-zinc-600 hover:text-zinc-300 transition-colors">&larr; portal</a>
      <a href="https://github.com/ion7-labs" class="font-mono text-xs text-zinc-500 hover:text-zinc-300 transition-colors">github &nearr;</a>
    </nav>
  </div>
</header>
]]

    -- Hero
    parts[#parts + 1] = string.format([[
<section class="max-w-5xl mx-auto px-6 md:px-14 pt-16 pb-12">
  <p class="font-mono text-xs text-zinc-700 uppercase tracking-[0.2em] mb-4">ion7-labs</p>
  <h1 class="text-4xl md:text-5xl font-mono font-semibold text-zinc-100 leading-tight mb-5 tracking-tight">
    API Overview
  </h1>
  <p class="text-zinc-500 text-sm leading-relaxed max-w-xl mb-8">
    LuaJIT &times; llama.cpp &mdash; modular local LLM runtime.<br>
    Each module is independent and usable standalone or as part of the full stack.
  </p>
  <div class="flex flex-wrap gap-6 pb-8 border-b border-zinc-800/40">
    <div>
      <span class="font-mono text-zinc-100 text-2xl font-semibold">%d</span>
      <span class="font-mono text-zinc-700 text-xs ml-2">documented functions</span>
    </div>
    <div>
      <span class="font-mono text-zinc-100 text-2xl font-semibold">%d</span>
      <span class="font-mono text-zinc-700 text-xs ml-2">modules available</span>
    </div>
    <div>
      <span class="font-mono text-zinc-600 text-2xl font-semibold">%d</span>
      <span class="font-mono text-zinc-700 text-xs ml-2">planned</span>
    </div>
  </div>
</section>
]], total_fns, #available, #planned)

    -- Available section
    parts[#parts + 1] = [[
<section class="max-w-5xl mx-auto px-6 md:px-14 pb-12">
  <p class="font-mono text-xs text-zinc-600 uppercase tracking-widest mb-5">
    Available &mdash; API reference
  </p>
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
]]
    for _, m in ipairs(available) do
        parts[#parts + 1] = available_card(m)
    end
    parts[#parts + 1] = "  </div>\n</section>\n"

    -- In Development section
    if #in_dev > 0 then
        parts[#parts + 1] = [[
<section class="max-w-5xl mx-auto px-6 md:px-14 pb-12">
  <p class="font-mono text-xs text-zinc-700 uppercase tracking-widest mb-5">
    In Development &mdash; docs coming
  </p>
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
]]
        for _, m in ipairs(in_dev) do
            parts[#parts + 1] = dev_card(m)
        end
        parts[#parts + 1] = "  </div>\n</section>\n"
    end

    -- Planned section
    if #planned > 0 then
        parts[#parts + 1] = [[
<section class="max-w-5xl mx-auto px-6 md:px-14 pb-20">
  <p class="font-mono text-xs text-zinc-800 uppercase tracking-widest mb-5">
    Planned
  </p>
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
]]
        for _, m in ipairs(planned) do
            parts[#parts + 1] = planned_card(m)
        end
        parts[#parts + 1] = "  </div>\n</section>\n"
    end

    -- Stack diagram (layer view)
    parts[#parts + 1] = [[
<section class="max-w-5xl mx-auto px-6 md:px-14 pb-20">
  <p class="font-mono text-xs text-zinc-700 uppercase tracking-widest mb-5">Stack layers</p>
  <div class="border border-zinc-800/30 rounded-xl overflow-hidden text-xs font-mono">
    <!-- Application layer -->
    <div class="bg-zinc-900/20 px-6 py-4 border-b border-zinc-800/30">
      <p class="text-zinc-700 text-xs uppercase tracking-widest mb-2">Application</p>
      <div class="flex flex-wrap gap-2">
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">Nyx companion</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">NPC AI</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-nvim</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-flow</span>
      </div>
    </div>
    <!-- High level -->
    <div class="bg-zinc-900/15 px-6 py-4 border-b border-zinc-800/30">
      <p class="text-zinc-700 text-xs uppercase tracking-widest mb-2">High-level</p>
      <div class="flex flex-wrap gap-2">
        <a href="grammar/" class="text-zinc-400 hover:text-zinc-200 border border-zinc-700/50 hover:border-zinc-600 px-3 py-1 rounded transition-colors">ion7-grammar</a>
        <span class="text-zinc-500 border border-zinc-700/40 px-3 py-1 rounded">ion7-llm</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-memory</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-rag</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-tts</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-stt</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-train</span>
      </div>
    </div>
    <!-- Mid -->
    <div class="bg-zinc-900/10 px-6 py-4 border-b border-zinc-800/30">
      <p class="text-zinc-700 text-xs uppercase tracking-widest mb-2">Mid-level</p>
      <div class="flex flex-wrap gap-2">
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-embed</span>
        <span class="text-zinc-600 border border-zinc-800/40 px-3 py-1 rounded">ion7-kv</span>
      </div>
    </div>
    <!-- Core -->
    <div class="bg-zinc-900/5 px-6 py-4">
      <p class="text-zinc-700 text-xs uppercase tracking-widest mb-2">Core</p>
      <div class="flex flex-wrap gap-2">
        <a href="core/" class="text-zinc-300 hover:text-zinc-100 border border-zinc-600/60 hover:border-zinc-500 px-3 py-1 rounded transition-colors font-semibold">ion7-core</a>
        <span class="text-zinc-700 border border-zinc-800/40 px-3 py-1 rounded">&darr; libllama.so + libcommon.a</span>
        <span class="text-zinc-700 border border-zinc-800/40 px-3 py-1 rounded">&darr; libggml.so (CUDA / CPU)</span>
      </div>
    </div>
  </div>
</section>
]]

    -- Footer
    parts[#parts + 1] = [[
<footer class="border-t border-zinc-800/40 px-6 md:px-14 py-8">
  <div class="max-w-5xl mx-auto flex items-center justify-between">
    <span class="font-mono text-zinc-800 text-xs">ion7-labs &mdash; 2026</span>
    <a href="index.html" class="font-mono text-zinc-700 hover:text-zinc-500 text-xs transition-colors">&larr; portal</a>
  </div>
</footer>
</body>
</html>
]]

    return table.concat(parts)
end

return theme
