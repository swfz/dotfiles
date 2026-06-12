-- core/keymaps.lua: basic.vim / tab.vim / mapping.vim からの移植
local map = vim.keymap.set

-- indent-blankline toggle (IBLDisable / IBLEnable 相当)
map("n", "<Esc>id", "<Cmd>IBLDisable<CR>",  { desc = "IBL disable" })
map("n", "<Esc>ie", "<Cmd>IBLEnable<CR>",   { desc = "IBL enable" })

-- number toggle
map("n", "<Esc>nn", "<Cmd>set nonu<CR><Esc>", { desc = "hide line numbers" })
map("n", "<Esc>nu", "<Cmd>set nu<CR><Esc>",   { desc = "show line numbers" })

-- clear search highlight
map("n", "<Esc><Esc>", "<Cmd>noh<CR><Esc>", { desc = "clear highlight" })

-- US keyboard: swap ; and :
if vim.env.KB_TYPE == "US" then
  map("n", ";", ":", { noremap = true, desc = "colon" })
  map("n", ":", ";", { noremap = true, desc = "semicolon" })
end

-- insert mode escape
map("i", "<C-j>", "<Esc>", { desc = "escape" })

-- date/time insert
map("i", ",todo", "<C-r>=strftime('%Y-%m-%d %a')<CR>", { desc = "insert todo date" })
map("i", ",date", "<C-r>=strftime('%Y-%m-%d')<CR>",     { desc = "insert date" })
map("i", ",time", "<C-r>=strftime('%H:%M:%S')<CR>",     { desc = "insert time" })

-- ── Tab operations (tab.vim から) ───────────────────────────────
-- t1〜t9 で tabnext N
for n = 1, 9 do
  map("n", "t" .. n, "<Cmd>tabnext " .. n .. "<CR>",
      { silent = true, desc = "tab " .. n })
end

map("n", "tc", "<Cmd>tablast | tabnew<CR>", { silent = true, desc = "new tab at end" })
map("n", "tx", "<Cmd>tabclose<CR>",          { silent = true, desc = "close tab" })
map("n", "tn", "<Cmd>tabnext<CR>",           { silent = true, desc = "next tab" })
map("n", "tp", "<Cmd>tabprevious<CR>",        { silent = true, desc = "prev tab" })
-- tl → Telescope buffers (Unite tab 代替)
map("n", "tl", "<Cmd>Telescope buffers<CR>",  { silent = true, desc = "list buffers" })

-- ── Telescope (ag.vim / Unite mru 代替) ─────────────────────────
map("n", "<Leader>mru", "<Cmd>Telescope oldfiles<CR>",    { desc = "recent files" })
map("n", "<Leader>ff",  "<Cmd>Telescope find_files<CR>",  { desc = "find files" })
map("n", "<Leader>gr",  "<Cmd>Telescope live_grep<CR>",   { desc = "live grep" })

-- ── Neotree (NERDTree / VimFiler 代替) ──────────────────────────
map("n", "<Leader>nt", "<Cmd>Neotree toggle<CR>",  { desc = "toggle neotree" })
map("n", "<Leader>vf", "<Cmd>Neotree reveal<CR>",  { desc = "reveal neotree" })

-- ── Comment (caw.vim 代替: nvim 組み込み gc) ─────────────────────
-- nvim 0.10+ には vim.comment が組み込まれている
-- remap=true で gcc / gc を呼び出す
map("n", "<Leader>c", "gcc", { remap = true, desc = "toggle comment" })
map("x", "<Leader>c", "gc",  { remap = true, desc = "toggle comment" })

-- ── Vimux ──────────────────────────────────────────────────────
-- VimuxOpenRunner
map("n", "<Leader>vlo", function()
  vim.cmd("VimuxOpenRunner")
end, { silent = true, desc = "vimux open runner" })

-- VimuxRunCommand with unnamed register (レジスタ " の内容)
map("n", "<Leader>vrr", function()
  vim.fn.VimuxRunCommand(vim.fn.getreg('"'))
end, { silent = true, desc = "vimux run register" })

-- VimuxSendText with unnamed register
map("n", "<Leader>vrp", function()
  vim.fn.VimuxSendText(vim.fn.getreg('"'))
end, { silent = true, desc = "vimux send register" })

-- VimuxRunFromYank: 現在行を VimuxRunCommand に渡す
map("n", "<Leader>vlr", function()
  vim.fn.VimuxRunCommand(vim.api.nvim_get_current_line())
end, { silent = true, desc = "vimux run current line" })

-- VimuxSendTextFromYank: 現在行を VimuxSendText に渡す
map("n", "<Leader>vlp", function()
  vim.fn.VimuxSendText(vim.api.nvim_get_current_line())
end, { silent = true, desc = "vimux send current line" })

-- ── Yanky (yankround 代替) ──────────────────────────────────────
-- yanky.nvim の設定は plugins/editor.lua 内で行うが、
-- Telescope 連携マッピングはここに置く
map("n", "<Leader>yr", "<Cmd>Telescope yank_history<CR>", { desc = "yank history" })
