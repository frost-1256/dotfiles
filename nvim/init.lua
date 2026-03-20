require("config.lazy")
require("mason").setup()
require("mason-lspconfig").setup()
require("nvim-tree").setup()
require("nvim-treesitter").setup()

-- nvim-cmp の設定
local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)  -- vsnip を使う場合
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), 
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
  }, {
    { name = 'buffer' },
  })
})

-- コマンドライン補完の設定
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  }),
  matching = { disallow_symbol_nonprefix_matching = false }
})

-- Lualine Configuration
local lualine = require("lualine")
lualine.setup()

vim.keymap.set('n', '<C-q>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-,>', ':BufferPrevious<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-.>', ':BufferNext<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-c>', ':BufferClose<CR>', { noremap = true, silent = true })
vim.o.pumheight = 10
vim.g.mapleader = ' '
