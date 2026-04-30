-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    -- e.g. { import = "plugins.hogefuga" },
    { import = "plugins.background" },
    { import = "plugins.nvim-lspconfig" },
    { import = "plugins.mason" },
    { import = "plugins.mason-lspconfig" },
    { import = "plugins.cmp" },
    { import = "plugins.nvim-tree"},
    { import = "plugins.lualine" },
    { import = "plugins.treesitter" },
    { import = "plugins.startup" },
    { import = "plugins.barbar" },
    { import = "plugins.autopairs" },
    { import = "plugins.cord" },
    { import = "plugins.lazygit" },
    { import = "plugins.trouble"},
    { import = "plugins.diffview" },
    { import = "plugins.toggleterm" }
  },
  -- automatically check for plugin updates
  checker = {
    enabled = true,
    notify = false,
  },
})
