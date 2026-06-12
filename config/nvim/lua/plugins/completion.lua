-- plugins/completion.lua
return {
  -- ── LuaSnip ──────────────────────────────────────────────────
  {
    "L3MON4D3/LuaSnip",
    lazy    = false,
    version = "v2.*",
    build   = "make install_jsregexp",
    config  = function()
      local luasnip = require("luasnip")

      -- snipmate 互換スニペットを config/snippets/ から読み込む
      require("luasnip.loaders.from_snipmate").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })

      -- <C-k>: expand or jump forward (insert & select モード)
      local map = vim.keymap.set
      map({ "i", "s" }, "<C-k>", function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        end
      end, { silent = true, desc = "luasnip expand or jump" })

      -- NOTE: <C-j> は core/keymaps.lua で Esc に割当済みのためジャンプバックは <S-Tab> を使う
    end,
  },

  {
    "saadparwaiz1/cmp_luasnip",
    lazy = true,
  },

  -- ── nvim-cmp ─────────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        -- 自動補完はデフォルトで有効 (neocomplcache_enable_at_startup=1 相当)
        mapping = cmp.mapping.preset.insert({
          -- <CR> で確定
          ["<CR>"] = cmp.mapping.confirm({ select = false }),

          -- <Tab>/<S-Tab> で候補移動 or スニペットジャンプ
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),

          -- scroll docs
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
        }),

        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
}
