-- plugins/telescope.lua
return {
  {
    "nvim-telescope/telescope.nvim",
    cmd          = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      defaults = {
        prompt_prefix    = " ",
        selection_caret  = " ",
        path_display     = { "truncate" },
        layout_strategy  = "horizontal",
        layout_config    = { horizontal = { preview_width = 0.55 } },
      },
    },
  },

  { "nvim-lua/plenary.nvim", lazy = true },
}
