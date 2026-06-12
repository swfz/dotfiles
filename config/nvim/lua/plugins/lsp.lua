-- plugins/lsp.lua: mason + mason-lspconfig + nvim-lspconfig
-- nvim 0.11+ は vim.lsp.config / vim.lsp.enable ベースで書く
return {
  -- ── Mason ────────────────────────────────────────────────────
  {
    "williamboman/mason.nvim",
    cmd    = "Mason",
    build  = ":MasonUpdate",
    config = true,
  },

  -- ── Mason-lspconfig ──────────────────────────────────────────
  {
    "williamboman/mason-lspconfig.nvim",
    lazy         = false,
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      -- 自動インストールはしない
      automatic_installation = false,
      -- インストール済みサーバを自動で有効化
      automatic_enable       = true,
    },
  },

  -- ── nvim-lspconfig ───────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    lazy         = false,
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- 診断設定 (ALE の on_save 運用に近い控えめ設定)
      vim.diagnostic.config({
        update_in_insert = false,
        virtual_text     = true,
        signs            = true,
        underline        = true,
      })

      -- 共通 on_attach: キーマッピングを設定
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("n", "gd",         vim.lsp.buf.definition,      "LSP: go to definition")
          map("n", "gr",         vim.lsp.buf.references,      "LSP: references")
          map("n", "K",          vim.lsp.buf.hover,            "LSP: hover")
          map("n", "<Leader>rn", vim.lsp.buf.rename,           "LSP: rename")
          map("n", "<Leader>ca", vim.lsp.buf.code_action,      "LSP: code action")
          map("n", "]d",         vim.diagnostic.goto_next,     "LSP: next diagnostic")
          map("n", "[d",         vim.diagnostic.goto_prev,     "LSP: prev diagnostic")
        end,
      })

      -- nvim 0.11+ の vim.lsp.config でデフォルト capabilities を設定
      local capabilities
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_lsp.default_capabilities()
      else
        capabilities = vim.lsp.protocol.make_client_capabilities()
      end

      -- よく使うサーバに capabilities を注入
      -- vim.lsp.config("*", ...) でグローバルデフォルト設定
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- lua_ls 専用設定: neovim API 認識
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime     = { version = "LuaJIT" },
            workspace   = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            diagnostics = { globals = { "vim" } },
            telemetry   = { enable = false },
          },
        },
      })
    end,
  },
}
