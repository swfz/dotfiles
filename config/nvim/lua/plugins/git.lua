-- plugins/git.lua
return {
  -- vim-fugitive
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gwrite", "Gread", "Gdiffsplit" },
  },

  -- gitsigns
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPost",
    opts  = {},
  },
}
