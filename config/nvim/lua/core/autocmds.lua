-- core/autocmds.lua: basic.vim の autocmd 群を移植
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- checktime on focus/buf enter
augroup("CheckTime", { clear = true })
autocmd({ "FocusGained", "BufEnter" }, {
  group = "CheckTime",
  pattern = "*",
  command = "checktime",
})

-- filetype overrides
augroup("FileTypeOverride", { clear = true })
autocmd({ "BufNewFile", "BufRead" }, {
  group = "FileTypeOverride",
  pattern = "*.tt",
  command = "set filetype=html",
})
autocmd({ "BufRead", "BufNewFile" }, {
  group = "FileTypeOverride",
  pattern = "*.tmp",
  command = "set filetype=tmp",
})
-- Dataform: sqls のアタッチとSQLハイライトを効かせる（config/js ブロックは誤検知あり）
autocmd({ "BufRead", "BufNewFile" }, {
  group = "FileTypeOverride",
  pattern = "*.sqlx",
  command = "set filetype=sql",
})

-- JSON: disable conceal
augroup("JsonConceal", { clear = true })
autocmd("FileType", {
  group = "JsonConceal",
  pattern = "json",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Trailing spaces highlight
augroup("HighlightTrailingSpaces", { clear = true })
autocmd({ "VimEnter", "WinEnter", "ColorScheme" }, {
  group = "HighlightTrailingSpaces",
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "TrailingSpaces", { ctermbg = "DarkCyan", bg = "darkcyan" })
  end,
})
autocmd({ "VimEnter", "WinEnter" }, {
  group = "HighlightTrailingSpaces",
  pattern = "*",
  callback = function()
    vim.fn.matchadd("TrailingSpaces", [[\s\+$]])
  end,
})

-- Transparency: bg=NONE for key highlight groups
augroup("TransparentBg", { clear = true })
autocmd({ "VimEnter", "ColorScheme" }, {
  group = "TransparentBg",
  pattern = "*",
  callback = function()
    local groups = { "Normal", "LineNr", "SignColumn", "VertSplit", "NonText" }
    for _, g in ipairs(groups) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
      if ok then
        hl.bg = nil
        hl.ctermbg = nil
        vim.api.nvim_set_hl(0, g, hl)
      end
    end
  end,
})

-- Search highlight colors
autocmd({ "VimEnter", "ColorScheme" }, {
  group = "TransparentBg",
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "IncSearch", {
      ctermfg = 17, ctermbg = 214,
      fg = "#00005f", bg = "#ffaf00",
    })
    vim.api.nvim_set_hl(0, "Search", {
      ctermfg = 17, ctermbg = 214,
      fg = "#00005f", bg = "#ffaf00",
    })
  end,
})
