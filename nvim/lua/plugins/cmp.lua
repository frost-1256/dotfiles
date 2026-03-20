return {
  { "hrsh7th/nvim-cmp"  },
  { 
    "hrsh7th/cmp-nvim-lsp",
    dependencies = { "nvim-cmp" },
    event = { "InsertEnter" },
  },
  {
    "hrsh7th/cmp-buffer",
    dependencies = { "nvim-cmp" },
    event = { "InsertEnter" },
  },
  {
    "hrsh7th/cmp-path",
    dependencies = { "nvim-cmp" },
    event = { "InsertEnter" },
  },
  {
    "hrsh7th/cmp-vsnip",
    dependencies = { "nvim-cmp", "vim-vsnip" },
    event = { "InsertEnter" },
  },
  {
    "hrsh7th/vim-vsnip",
    event = { "InsertEnter" },
  },
}
