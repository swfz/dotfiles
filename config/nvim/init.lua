-- init.lua: lazy.nvim bootstrap + core require
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key must be set before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Core settings
require("core.options")
require("core.autocmds")
require("core.tabline")

-- Plugins
require("lazy").setup({
  { import = "plugins.ui" },
  { import = "plugins.editor" },
  { import = "plugins.completion" },
  { import = "plugins.lsp" },
  { import = "plugins.telescope" },
  { import = "plugins.git" },
  { import = "plugins.tmux" },
}, {
  defaults = { lazy = true },
  install = { colorscheme = { "solarized" } },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- Keymaps must be loaded after plugins are set up
require("core.keymaps")
