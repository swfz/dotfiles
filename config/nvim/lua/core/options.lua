-- core/options.lua: basic.vim からの移植
local opt = vim.opt

-- Indentation
opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 4
opt.smartindent  = true
opt.autoindent   = true

-- Search
opt.smartcase    = true
opt.wrapscan     = false   -- nowrapscan
opt.incsearch    = true
opt.hlsearch     = true

-- Display
opt.number       = true
opt.showmatch    = true
opt.laststatus   = 2
opt.showtabline  = 2
opt.termguicolors = true
opt.background   = "dark"
opt.list         = true
opt.listchars    = { tab = ">.", trail = "_", extends = ">", precedes = "<", nbsp = "%" }

-- Files
opt.autoread     = true
opt.encoding     = "utf-8"
opt.fileencoding = "utf-8"
opt.fileencodings = { "utf-8" }

-- Editing
opt.backspace    = { "indent", "eol", "start" }

-- Clipboard
-- WSL では X/Wayland プロバイダが使えず clipboard=unnamed だと無名レジスタが
-- 壊れたシステムクリップボードに紐づき dd/p/yy が機能しなくなる。
-- Win との同期は不要なので設定せず、nvim 内部レジスタで完結させる。
-- OS へコピーしたい場合のみ明示的に "+y / "+p を使う想定。
