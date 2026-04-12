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
      <span class="text-zinc-700 text-xs font-mono">v2.0.0</span>
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

function theme.api_index(n_modules, n_fns, cat_order, cat_groups)
    local parts = {}

    -- Header
    parts[#parts + 1] = string.format([[
<p class="text-zinc-700 text-xs font-mono uppercase tracking-widest mb-3">api reference</p>
<h1 class="text-2xl font-semibold text-zinc-100 tracking-tight mb-2 font-mono">ion7-core</h1>
<p class="text-zinc-600 text-sm leading-relaxed mb-8 max-w-lg">LuaJIT FFI bindings for llama.cpp. Direct calls into libllama.so — no subprocess, no HTTP, no allocations per token.</p>
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
]], n_modules, n_fns)

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

function theme.landing_page(corpus)
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

    -- Module cards
    local modules = {
        {
            name   = "ion7-core",
            status = "stable v1.1",
            desc   = "LuaJIT FFI &rarr; llama.cpp. Zero malloc per token. 84 bridge functions, 4 translation units.",
            href   = "api/",
        },
        {
            name   = "ion7-grammar",
            status = "beta v0.1",
            desc   = "GBNF engine in pure Lua. JSON Schema, regex, tool calling, CRANE-style lazy grammar.",
        },
        {
            name   = "ion7-llm",
            status = "beta v0.1",
            desc   = "High-level chat pipeline. Prefix cache, sliding window, attention sink, streaming.",
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
      <a href="api/" class="font-mono text-xs text-zinc-500 hover:text-zinc-300 transition-colors">docs</a>
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
      Local LLM inference runtime for LuaJIT. Zero Python. Zero HTTP overhead.<br>
      Direct FFI into libllama.so &mdash; microseconds, not milliseconds.
    </p>
    <div class="flex flex-wrap gap-3">
      <a href="api/" class="font-mono text-sm bg-zinc-100 text-zinc-950 hover:bg-white px-6 py-3 rounded transition-colors font-medium">
        API Reference &rarr;
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
      <p class="font-mono text-2xl font-semibold text-zinc-100">~15ms</p>
      <p class="font-mono text-xs text-zinc-600 mt-1">startup time</p>
    </div>
    <div>
      <p class="font-mono text-2xl font-semibold text-zinc-100">0</p>
      <p class="font-mono text-xs text-zinc-600 mt-1">malloc / token</p>
    </div>
    <div>
      <p class="font-mono text-2xl font-semibold text-zinc-100">%d</p>
      <p class="font-mono text-xs text-zinc-600 mt-1">documented functions</p>
    </div>
    <div>
      <p class="font-mono text-2xl font-semibold text-zinc-100">262k</p>
      <p class="font-mono text-xs text-zinc-600 mt-1">native context tokens</p>
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
    <a href="api/" class="font-mono text-zinc-700 hover:text-zinc-500 text-xs transition-colors">API Reference &rarr;</a>
  </div>
</footer>

</body>
</html>
]]

    return table.concat(parts)
end

return theme
