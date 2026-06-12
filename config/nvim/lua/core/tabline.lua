-- core/tabline.lua: tab.vim の my_tabline を Lua で忠実再現
local M = {}

-- tab.vim の hi 定義を移植
-- ctermfg=219 → #ffafff, ctermbg=024 → #005f87
-- ctermfg=236 → #303030, ctermbg=075 → #5fafff
-- ctermfg=117 → #87d7ff
local function setup_highlights()
  vim.api.nvim_set_hl(0, "TabLineSel", {
    bold = true, underline = true,
    ctermfg = 219, ctermbg = 24,
    fg = "#ffafff", bg = "#005f87",
  })
  vim.api.nvim_set_hl(0, "TabLineFill", {
    reverse = true, bold = true,
    ctermfg = 236, ctermbg = 75,
    fg = "#303030", bg = "#5fafff",
  })
  vim.api.nvim_set_hl(0, "TabLine", {
    underline = true,
    ctermfg = 117, ctermbg = 236,
    fg = "#87d7ff", bg = "#303030",
  })
end

--- Render the tabline string (called by vim.o.tabline)
function M.render()
  local s = ""
  local current = vim.fn.tabpagenr()
  local total   = vim.fn.tabpagenr("$")

  for i = 1, total do
    local bufnrs = vim.fn.tabpagebuflist(i)
    local bufnr  = bufnrs[vim.fn.tabpagewinnr(i)]
    local mod    = vim.fn.getbufvar(bufnr, "&modified") == 1 and "!" or " "
    local title  = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":t")
    if title == "" then title = "[No Name]" end
    title = "[" .. title .. "]"

    s = s .. "%" .. i .. "T"
    s = s .. "%#" .. (i == current and "TabLineSel" or "TabLine") .. "#"
    s = s .. i .. ":" .. title
    s = s .. mod
    s = s .. "%#TabLineFill# "
  end

  s = s .. "%#TabLineFill#%T%=%#TabLine#"
  return s
end

-- Set up highlights on ColorScheme change
vim.api.nvim_create_augroup("TablineHL", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = "TablineHL",
  pattern = "*",
  callback = setup_highlights,
})

-- Register the tabline expression
vim.o.tabline = "%!v:lua.require('core.tabline').render()"

return M
