--- Minimal Markdown → HTML renderer for ion7-doc.
--- Handles the subset used in ion7-core README files:
---   # H1  ## H2  ### H3
---   ```lang ... ```  code blocks
---   `inline code`
---   **bold**  _italic_
---   [text](url)  [![alt](img)](url)  (badge images → stripped)
---   - list items  (unordered only)
---   ---  horizontal rule
---   blank line = paragraph break

local md = {}

-- ── Inline transforms ─────────────────────────────────────────────────────────

local function escape(s)
    return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function inline(s)
    s = escape(s)
    -- Badge images [![alt](img)](url) → strip entirely (shields.io noise)
    s = s:gsub("%[!%[.-%]%(.-%)%]%(.-%)", "")
    -- Links [text](url)
    s = s:gsub("%[(.-)%]%((.-)%)", function(text, url)
        return string.format('<a href="%s" class="text-zinc-300 underline decoration-zinc-600 hover:decoration-zinc-400 transition-colors">%s</a>', url, text)
    end)
    -- Bold **text**
    s = s:gsub("%*%*(.-)%*%*", '<strong class="text-zinc-200 font-medium">%1</strong>')
    -- Italic _text_ or *text*
    s = s:gsub("_(.-)_", "<em>%1</em>")
    s = s:gsub("%*(.-)%*",  "<em>%1</em>")
    -- Inline code `code`
    s = s:gsub("`([^`]+)`", '<code class="font-mono text-zinc-300 bg-zinc-800/70 px-1.5 py-0.5 rounded text-xs">%1</code>')
    return s
end

-- ── Block renderer ────────────────────────────────────────────────────────────

--- Convert a Markdown string to an HTML string.
--- @param  source  string  Raw Markdown text.
--- @return string          HTML fragment (no <html>/<body> wrapper).
function md.to_html(source)
    local lines  = {}
    for line in (source .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = line
    end

    local out         = {}
    local i           = 1
    local in_list     = false
    local para_lines  = {}

    local function flush_para()
        if #para_lines == 0 then return end
        local text = table.concat(para_lines, " ")
        -- Don't emit empty paragraphs
        if text:match("%S") then
            out[#out + 1] = '<p class="text-zinc-400 text-sm leading-relaxed mb-4">' .. inline(text) .. "</p>\n"
        end
        para_lines = {}
    end

    local function close_list()
        if in_list then
            out[#out + 1] = "</ul>\n"
            in_list = false
        end
    end

    while i <= #lines do
        local line = lines[i]

        -- Fenced code block ```lang
        if line:match("^```") then
            flush_para()
            close_list()
            local lang = line:match("^```(%a*)") or ""
            local code_lines = {}
            i = i + 1
            while i <= #lines and not lines[i]:match("^```") do
                code_lines[#code_lines + 1] = lines[i]
                    :gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
                i = i + 1
            end
            -- strip trailing blank lines
            while code_lines[#code_lines] == "" do
                table.remove(code_lines)
            end
            local lang_label = lang ~= "" and
                string.format('<span class="text-zinc-700 text-xs font-mono absolute top-3 right-4">%s</span>', lang) or ""
            out[#out + 1] = string.format(
                '<div class="relative mb-6"><pre class="bg-zinc-900 border border-zinc-800 rounded-lg px-5 py-4 text-xs font-mono text-zinc-300 overflow-x-auto leading-relaxed">%s<code>%s</code></pre></div>\n',
                lang_label, table.concat(code_lines, "\n"))
            i = i + 1

        -- Horizontal rule ---
        elseif line:match("^%-%-%-+%s*$") or line:match("^%*%*%*+%s*$") then
            flush_para()
            close_list()
            out[#out + 1] = '<hr class="border-zinc-800 my-8">\n'
            i = i + 1

        -- H1
        elseif line:match("^# ") then
            flush_para()
            close_list()
            local text = line:match("^# (.+)")
            out[#out + 1] = string.format(
                '<h1 class="text-2xl font-semibold text-zinc-100 tracking-tight mt-2 mb-4">%s</h1>\n',
                inline(text))
            i = i + 1

        -- H2
        elseif line:match("^## ") then
            flush_para()
            close_list()
            local text = line:match("^## (.+)")
            out[#out + 1] = string.format(
                '<h2 class="text-base font-semibold text-zinc-200 mt-10 mb-3 pb-2 border-b border-zinc-800/60">%s</h2>\n',
                inline(text))
            i = i + 1

        -- H3
        elseif line:match("^### ") then
            flush_para()
            close_list()
            local text = line:match("^### (.+)")
            out[#out + 1] = string.format(
                '<h3 class="text-sm font-semibold text-zinc-300 mt-7 mb-2">%s</h3>\n',
                inline(text))
            i = i + 1

        -- H4
        elseif line:match("^#### ") then
            flush_para()
            close_list()
            local text = line:match("^#### (.+)")
            out[#out + 1] = string.format(
                '<h4 class="text-xs font-semibold text-zinc-400 uppercase tracking-widest mt-5 mb-2">%s</h4>\n',
                inline(text))
            i = i + 1

        -- Table row (|---|) — skip separator rows, render data rows
        elseif line:match("^|") then
            flush_para()
            close_list()
            -- Collect all table lines
            local tlines = {}
            while i <= #lines and lines[i]:match("^|") do
                tlines[#tlines + 1] = lines[i]
                i = i + 1
            end
            -- Build table
            out[#out + 1] = '<div class="overflow-x-auto mb-6"><table class="w-full text-xs font-mono border-collapse">\n'
            local is_header = true
            for _, tl in ipairs(tlines) do
                -- skip separator rows like |---|---|
                if tl:match("^|[%s%-|]+|$") then
                    is_header = false
                else
                    local cells = {}
                    for cell in tl:gmatch("|([^|]+)") do
                        cells[#cells + 1] = cell:match("^%s*(.-)%s*$")
                    end
                    if is_header then
                        out[#out + 1] = "<thead><tr>\n"
                        for _, c in ipairs(cells) do
                            out[#out + 1] = string.format(
                                '<th class="text-left text-zinc-600 uppercase tracking-widest py-2 pr-6 border-b border-zinc-800 font-medium">%s</th>\n',
                                inline(c))
                        end
                        out[#out + 1] = "</tr></thead><tbody>\n"
                    else
                        out[#out + 1] = '<tr class="border-b border-zinc-800/40 hover:bg-zinc-900/40 transition-colors">\n'
                        for j, c in ipairs(cells) do
                            local cls = j == 1
                                and 'class="py-2 pr-6 text-zinc-300"'
                                or  'class="py-2 pr-6 text-zinc-500"'
                            out[#out + 1] = string.format("<td %s>%s</td>\n", cls, inline(c))
                        end
                        out[#out + 1] = "</tr>\n"
                    end
                end
            end
            out[#out + 1] = "</tbody></table></div>\n"

        -- List item - text
        elseif line:match("^%s*%- ") then
            flush_para()
            if not in_list then
                out[#out + 1] = '<ul class="space-y-1 mb-4 ml-4">\n'
                in_list = true
            end
            local text = line:match("^%s*%- (.+)")
            out[#out + 1] = string.format(
                '<li class="flex gap-2 text-sm text-zinc-400"><span class="text-zinc-700 shrink-0 mt-0.5">—</span><span>%s</span></li>\n',
                inline(text or ""))
            i = i + 1

        -- Blank line
        elseif line:match("^%s*$") then
            flush_para()
            close_list()
            i = i + 1

        -- Regular text → accumulate into paragraph
        else
            close_list()
            para_lines[#para_lines + 1] = line
            i = i + 1
        end
    end

    flush_para()
    close_list()
    return table.concat(out)
end

return md
