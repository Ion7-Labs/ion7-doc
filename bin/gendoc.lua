#!/usr/bin/env luajit
--- ion7-doc - entry point
---
--- Usage:
---   luajit bin/gendoc.lua [src_dir] [out_dir]
---
--- Defaults:
---   src_dir = ../ion7-core/src/ion7/core
---   out_dir = docs/

-- ── Path setup ────────────────────────────────────────────────────────────────
-- Allow running from anywhere inside ion7-doc/
local script_dir = debug.getinfo(1, "S").source:match("^@(.+)/[^/]+$") or "."
local root = script_dir .. "/.."

package.path = root .. "/?.lua;"
            .. root .. "/?/init.lua;"
            .. package.path

-- ── Args ──────────────────────────────────────────────────────────────────────

local src_dir    = arg[1] or (root .. "/../ion7-core/src/ion7/core")
local out_dir    = arg[2] or (root .. "/docs")
local readme     = arg[3] or (root .. "/../ion7-core/README.md")

-- ── File list (explicit order → sidebar order) ────────────────────────────────
-- Mirrors the source structure of ion7-core.
local files = {
    src_dir .. "/init.lua",
    src_dir .. "/model.lua",
    src_dir .. "/model/inspect.lua",
    src_dir .. "/model/meta.lua",
    src_dir .. "/model/lora.lua",
    src_dir .. "/model/quantize.lua",
    src_dir .. "/model/context_factory.lua",
    src_dir .. "/context.lua",
    src_dir .. "/context/decode.lua",
    src_dir .. "/context/kv.lua",
    src_dir .. "/context/state.lua",
    src_dir .. "/context/logits.lua",
    src_dir .. "/vocab.lua",
    src_dir .. "/sampler.lua",
    src_dir .. "/sampler/common.lua",
    src_dir .. "/custom_sampler.lua",
    src_dir .. "/threadpool.lua",
    src_dir .. "/speculative.lua",
}

-- ── Run ───────────────────────────────────────────────────────────────────────

local parser   = require "parser"
local renderer = require "renderer.html"

-- Ensure output dir exists
os.execute('mkdir -p "' .. out_dir .. '"')

io.write("[ion7-doc] parsing " .. #files .. " source files...\n")
local corpus = parser.parse_dir(src_dir, files)
io.write("[ion7-doc] parsed  " .. #corpus .. " modules\n\n")

renderer.render(corpus, out_dir, readme)

io.write("\nDone. Open " .. out_dir .. "/index.html\n")
