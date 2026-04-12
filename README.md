# ion7-doc

HTML documentation generator for the ion7-labs stack.  
Parses ion7-style Lua doc comments and produces a static site with a dark theme.

## Usage

```bash
luajit bin/gendoc.lua <src_dir> <out_dir>
```

Output: `out_dir/index.html` (landing page) + `out_dir/api/` (API reference).

## Doc comment format

```lua
--- @module ion7.core.example
--- Short description of the module.

--- Does something useful.
--- @param  input   string   The input value.
--- @param  flag    bool?    Optional flag (default: false).
--- @return string           The result.
--- @error  If input is nil.
--- @usage
---   local result = example.process("hello")
function example.process(input, flag)
```

Supported tags: `@module`, `@class`, `@field`, `@param`, `@return`, `@error`, `@usage`.

## Structure

```
bin/gendoc.lua       entry point
parser/init.lua      doc comment parser
renderer/html.lua    page assembler
themes/dark.lua      HTML/CSS/JS theme
```

## Integration

ion7-core calls this via `make docs`. A GitHub Actions workflow in ion7-core
auto-builds and pushes the output to ion7-labs.github.io on every push to main.
