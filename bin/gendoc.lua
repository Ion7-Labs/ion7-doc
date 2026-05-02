#!/usr/bin/env luajit
--- ion7-doc — entry point
---
--- Usage:
---   luajit bin/gendoc.lua <module> [out_dir] [readme]
---
--- Modules:
---   core     ion7-core   (default when no arg)
---   grammar  ion7-grammar
---   llm      ion7-llm
---   all      every module, each under out_dir/<id>/
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
        -- Class modules + their mixins
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
        -- Pure-Lua utilities re-exported at the top level (ion7.utf8,
        -- ion7.base64, ion7.log, ion7.tensor).
        src .. "/util/utf8.lua",
        src .. "/util/base64.lua",
        src .. "/util/log.lua",
        src .. "/util/tensor.lua",
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

local function llm_module()
    local src = root .. "/../ion7-llm/src/ion7/llm"
    local files = {
        -- Entry point + top-level classes
        src .. "/init.lua",
        src .. "/engine.lua",
        src .. "/pool.lua",
        src .. "/session.lua",
        src .. "/response.lua",
        src .. "/embed.lua",
        src .. "/stop.lua",
        -- KV layer
        src .. "/kv/init.lua",
        src .. "/kv/slots.lua",
        src .. "/kv/prefix.lua",
        src .. "/kv/snapshot.lua",
        src .. "/kv/eviction.lua",
        -- Chat-template + demux helpers
        src .. "/chat/template.lua",
        src .. "/chat/thinking.lua",
        src .. "/chat/parse.lua",
        src .. "/chat/stream.lua",
        -- Sampler shortcuts
        src .. "/sampler/profiles.lua",
        src .. "/sampler/schema.lua",
        src .. "/sampler/budget.lua",
        -- Tools
        src .. "/tools/spec.lua",
        src .. "/tools/loop.lua",
        -- Pure-Lua helpers
        src .. "/util/messages.lua",
        src .. "/util/partial_json.lua",
        src .. "/util/log.lua",
    }
    return {
        src     = src,
        files   = files,
        out_dir = out_base .. "/llm",
        readme  = readme_arg or (root .. "/../ion7-llm/README.md"),
        label   = "ion7-llm",
        id      = "llm",
        prefix  = "ion7%.llm%.?",
        desc    = "Chat pipeline + multi-session inference orchestration on top of ion7-core. Per-seq KV snapshots, prefix cache, three-channel streaming, schema-constrained sampling, interleaved-thinking tool loop, embeddings.",
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
    local llm_corpus     = run(llm_module())
    -- Combine corpora so the portal and api overview show real function counts
    local combined = {}
    for _, fr in ipairs(core_corpus)    do combined[#combined + 1] = fr end
    for _, fr in ipairs(grammar_corpus) do combined[#combined + 1] = fr end
    for _, fr in ipairs(llm_corpus)     do combined[#combined + 1] = fr end
    renderer.render_portal(out_base, combined)
    renderer.render_api(out_base, combined)
elseif module_arg == "grammar" then
    run(grammar_module())
elseif module_arg == "llm" then
    run(llm_module())
else
    run(core_module())
end
