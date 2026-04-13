#!/usr/bin/env luajit
--- ion7-doc — entry point
---
--- Usage:
---   luajit bin/gendoc.lua <module> [out_dir] [readme]
---
--- Modules:
---   core     ion7-core   (default when no arg)
---   grammar  ion7-grammar
---   all      both, under out_dir/core/ and out_dir/grammar/
---
--- Defaults:
---   out_dir = docs/
---   readme  = inferred from module

-- ── Path setup ────────────────────────────────────────────────────────────────
local script_dir = debug.getinfo(1, "S").source:match("^@(.+)/[^/]+$") or "."
local root = script_dir .. "/.."

package.path = root .. "/?.lua;"
            .. root .. "/?/init.lua;"
            .. package.path

-- ── Args ──────────────────────────────────────────────────────────────────────

local module_arg = arg[1] or "core"
local out_base   = arg[2] or (root .. "/docs")
local readme_arg = arg[3]  -- optional override

-- ── Module definitions ────────────────────────────────────────────────────────

local function core_module()
    local src = root .. "/../ion7-core/src/ion7/core"
    local files = {
        src .. "/init.lua",
        src .. "/model.lua",
        src .. "/model/inspect.lua",
        src .. "/model/meta.lua",
        src .. "/model/lora.lua",
        src .. "/model/quantize.lua",
        src .. "/model/context_factory.lua",
        src .. "/context.lua",
        src .. "/context/decode.lua",
        src .. "/context/kv.lua",
        src .. "/context/state.lua",
        src .. "/context/logits.lua",
        src .. "/vocab.lua",
        src .. "/sampler.lua",
        src .. "/sampler/common.lua",
        src .. "/custom_sampler.lua",
        src .. "/threadpool.lua",
        src .. "/speculative.lua",
    }
    return {
        src     = src,
        files   = files,
        out_dir = out_base .. "/core",
        readme  = readme_arg or (root .. "/../ion7-core/README.md"),
        label   = "ion7-core",
        id      = "core",
        prefix  = "ion7%.core%.?",
        desc    = "LuaJIT FFI bindings for llama.cpp. Direct calls into libllama.so — no subprocess, no HTTP, no allocations per token.",
    }
end

local function grammar_module()
    local src = root .. "/../ion7-grammar/src/ion7/grammar"
    local files = {
        -- Entry point
        src .. "/init.lua",
        src .. "/grammar_obj.lua",
        -- AST layer
        src .. "/ast/init.lua",
        src .. "/ast/nodes.lua",
        src .. "/ast/builder.lua",
        src .. "/ast/compiler.lua",
        src .. "/ast/walk.lua",
        -- Constructors
        src .. "/from/regex.lua",
        src .. "/from/json/init.lua",
        src .. "/from/json/converter.lua",
        src .. "/from/types.lua",
        src .. "/from/dynamic.lua",
        -- Composition & complement
        src .. "/compose.lua",
        src .. "/except.lua",
        -- Runtime (ion7-core required)
        src .. "/runtime/context.lua",
        src .. "/runtime/backtrack.lua",
        src .. "/runtime/dccd.lua",
        -- Dev tools
        src .. "/dev/fuzz.lua",
        src .. "/dev/debug.lua",
    }
    return {
        src     = src,
        files   = files,
        out_dir = out_base .. "/grammar",
        readme  = readme_arg or (root .. "/../ion7-grammar/README.md"),
        label   = "ion7-grammar",
        id      = "grammar",
        prefix  = "ion7%.grammar%.?",
        desc    = "GBNF grammar engine in pure Lua. JSON Schema, regex, tool calling, CRANE-style lazy grammar activation.",
    }
end

-- ── Runner ────────────────────────────────────────────────────────────────────

local parser   = require "parser"
local renderer = require "renderer.html"

local function run(mod)
    os.execute('mkdir -p "' .. mod.out_dir .. '"')
    io.write("[ion7-doc] " .. mod.label .. " — parsing " .. #mod.files .. " files...\n")
    local corpus = parser.parse_dir(mod.src, mod.files)
    io.write("[ion7-doc] parsed " .. #corpus .. " modules\n")
    renderer.render(corpus, mod.out_dir, mod.readme, {
        label  = mod.label,
        id     = mod.id,
        prefix = mod.prefix,
        desc   = mod.desc,
    })
    io.write("[ion7-doc] done → " .. mod.out_dir .. "/index.html\n\n")
    return corpus
end

if module_arg == "all" then
    local core_corpus    = run(core_module())
    local grammar_corpus = run(grammar_module())
    -- Combine corpora so the portal and api overview show real function counts
    local combined = {}
    for _, fr in ipairs(core_corpus)    do combined[#combined + 1] = fr end
    for _, fr in ipairs(grammar_corpus) do combined[#combined + 1] = fr end
    renderer.render_portal(out_base, combined)
    renderer.render_api(out_base, combined)
elseif module_arg == "grammar" then
    run(grammar_module())
else
    run(core_module())
end
