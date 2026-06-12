-- plugins/ui.lua
return {
  -- ── Colorscheme ──────────────────────────────────────────────
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style        = "dark",
      transparent  = { enabled = true },
    },
    config = function(_, opts)
      require("solarized").setup(opts)
      vim.cmd("colorscheme solarized")
    end,
  },

  -- ── Statusline ───────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    lazy    = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local ok_theme, theme = pcall(require, "lualine.themes.wombat")
      local selected_theme = ok_theme and "wombat" or "auto"

      require("lualine").setup({
        options = {
          theme = selected_theme,
          globalstatus = false,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            { "branch" },
            { "diff" },
            {
              "filename",
              path = 1,
              symbols = { modified = " [+]", readonly = " [RO]" },
            },
          },
          lualine_c = {},
          lualine_x = { "location", "progress" },
          lualine_y = { "fileformat", "encoding", "filetype" },
          lualine_z = {},
        },
      })
    end,
  },

  -- ── Indent blankline ─────────────────────────────────────────
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    main  = "ibl",
    opts  = {
      indent = {
        char      = "│",
        highlight = { "IblIndent" },
      },
      scope = { enabled = false },
    },
    config = function(_, opts)
      -- indentline.vim の色設定を移植
      vim.api.nvim_set_hl(0, "IblIndent", { ctermfg = 245, fg = "#A4E57E" })
      require("ibl").setup(opts)
    end,
  },

  -- ── Neo-tree (NERDTree / VimFiler 代替) ──────────────────────
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch       = "v3.x",
    cmd          = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      filesystem = {
        filtered_items = { visible = true },
        follow_current_file = { enabled = true },
      },
    },
  },
}
