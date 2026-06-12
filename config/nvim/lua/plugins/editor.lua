-- plugins/editor.lua
return {
  -- ── Surround ─────────────────────────────────────────────────
  {
    "kylechui/nvim-surround",
    event   = "BufReadPost",
    version = "*",
    config  = true,
  },

  -- ── Autopairs ────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event  = "InsertEnter",
    config = true,
  },

  -- ── Yanky (yankround 代替) ────────────────────────────────────
  {
    "gbprod/yanky.nvim",
    lazy    = false,
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("yanky").setup({
        ring        = { history_length = 50 },
        highlight   = { on_put = true, on_yank = true, timer = 200 },
      })

      local map = vim.keymap.set
      -- put (p/P を yanky 経由に)
      map({ "n", "x" }, "p",  "<Plug>(YankyPutAfter)",  { desc = "yanky put after" })
      map({ "n", "x" }, "P",  "<Plug>(YankyPutBefore)", { desc = "yanky put before" })
      -- history cycle
      map("n", "<C-p>", "<Plug>(YankyCycleForward)",  { desc = "yanky cycle forward" })
      map("n", "<C-n>", "<Plug>(YankyCycleBackward)", { desc = "yanky cycle backward" })

      -- Telescope 連携
      require("telescope").load_extension("yank_history")
    end,
  },

  -- ── Submode (ウィンドウリサイズ) ──────────────────────────────
  {
    "kana/vim-submode",
    lazy = false,
    config = function()
      vim.cmd([[
        call submode#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
        call submode#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
        call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>+')
        call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>-')
        call submode#map('winsize', 'n', '', '>', '<C-w>>')
        call submode#map('winsize', 'n', '', '<', '<C-w><')
        call submode#map('winsize', 'n', '', '+', '<C-w>+')
        call submode#map('winsize', 'n', '', '-', '<C-w>-')
      ]])
    end,
  },

  -- ── QuickHL ──────────────────────────────────────────────────
  {
    "t9md/vim-quickhl",
    lazy = false,
    config = function()
      local map = vim.keymap.set
      map({ "n", "x" }, "<Space>m", "<Plug>(quickhl-manual-this)",   { desc = "quickhl add" })
      map({ "n", "x" }, "<Space>M", "<Plug>(quickhl-manual-reset)",  { desc = "quickhl reset" })
      map("n",           "<Space>j", "<Plug>(quickhl-cword-toggle)",  { desc = "quickhl cword" })
      map("n",           "<Space>]", "<Plug>(quickhl-tag-toggle)",    { desc = "quickhl tag" })
      map({ "n", "x" }, "H",        "<Plug>(operator-quickhl-manual-this-motion)", { desc = "quickhl motion" })
    end,
  },

  -- ── Linediff ─────────────────────────────────────────────────
  {
    "AndrewRadev/linediff.vim",
    cmd = "Linediff",
  },

  -- ── Emmet ────────────────────────────────────────────────────
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "scss", "less", "javascriptreact", "typescriptreact", "vue" },
  },

  -- ── QuickRun ─────────────────────────────────────────────────
  {
    "thinca/vim-quickrun",
    cmd = "QuickRun",
  },

  -- ── Speeddating ──────────────────────────────────────────────
  {
    "tpope/vim-speeddating",
    event = "BufReadPost",
  },

  -- ── Treesitter ───────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    branch   = "master",
    lazy     = false,
    build    = ":TSUpdate",
    config   = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc",
          "javascript", "typescript", "tsx",
          "json", "yaml",
          "markdown", "markdown_inline",
          "bash",
          "ruby", "perl", "go", "python",
          "html", "css",
        },
        auto_install       = false,
        sync_install       = false,
        highlight          = { enable = true },
        indent             = { enable = true },
      })
    end,
  },
}
