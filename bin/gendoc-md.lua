#!/usr/bin/env luajit
--- ion7-doc — markdown generator entry point.
---
--- Walks a Lua source tree, parses ion7-style doc comments, and writes
--- one markdown file per source file plus a README.md index. Designed
--- for Obsidian-friendly consumption (flat layout, wikilinks, idiomatic
--- markdown headings).
---
--- Usage:
---   luajit bin/gendoc-md.lua <src_dir> <out_dir> [label] [desc]
---
--- Example:
---   luajit bin/gendoc-md.lua \
---       ../ion7-rag/src \
---       ~/Documents/Documentations/Ion7-Labs/ion7-rag/api \
---       "ion7-rag" \
---       "Local-first RAG library on top of ion7-core / ion7-llm / ion7-grammar."

-- Resolve module paths relative to ion7-doc's checkout, regardless of CWD.
local function _doc_root()
    local src = debug.getinfo(1, "S").source:sub(2)  -- drop leading '@'
    return src:match("(.+)/bin/gendoc%-md%.lua$") or "."
end
package.path = _doc_root() .. "/?.lua;" .. _doc_root() .. "/?/init.lua;" .. package.path

local parser   = require "parser"
local renderer = require "renderer.markdown"

-- ── Args ─────────────────────────────────────────────────────────────────────

local src_dir = arg[1]
local out_dir = arg[2]
local label   = arg[3] or "ion7"
local desc    = arg[4] or ""

if not src_dir or not out_dir then
    io.stderr:write([[
Usage: luajit bin/gendoc-md.lua <src_dir> <out_dir> [label] [desc]

Walks <src_dir> recursively for .lua files, parses ion7-style doc
comments, and emits one markdown file per source plus a README.md
index into <out_dir>.
]])
    os.exit(2)
end

-- ── Recursive .lua collector ─────────────────────────────────────────────────

local function find_lua(dir)
    local list = {}
    local p = io.popen("find '" .. dir .. "' -type f -name '*.lua' 2>/dev/null")
    if not p then return list end
    for line in p:lines() do list[#list + 1] = line end
    p:close()
    table.sort(list)
    return list
end

-- ── mkdir -p ──────────────────────────────────────────────────────────────────

local function mkdir_p(path)
    os.execute("mkdir -p '" .. path .. "'")
end

-- ── Run ──────────────────────────────────────────────────────────────────────

mkdir_p(out_dir)

local files = find_lua(src_dir)
if #files == 0 then
    io.stderr:write("[gendoc-md] no .lua files found under " .. src_dir .. "\n")
    os.exit(1)
end

local corpus = parser.parse_dir(src_dir, files)
io.write(string.format("[gendoc-md] parsed %d files\n", #corpus))

renderer.render(corpus, out_dir, { label = label, desc = desc })
io.write(string.format("[gendoc-md] wrote API to %s/\n", out_dir))
