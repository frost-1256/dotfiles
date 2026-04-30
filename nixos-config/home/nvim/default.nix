{pkgs, ...}: {
  home.packages = with pkgs; [
    lazygit
  ];

  xdg.configFile."nvim/colors/kipferl.lua".source = ../nvim-old/colors/kipfel.lua;

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = " ";
      maplocalleader = "\\";
      everforest_enable_italic = true;
      barbar_auto_setup = false;
    };

    opts = {
      pumheight = 10;
      termguicolors = true;
      winblend = 0;
      pumblend = 0;
    };

    plugins.treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      transparent-nvim
      everforest
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      cmp-vsnip
      vim-vsnip
      nvim-tree-lua
      nvim-web-devicons
      lualine-nvim
      telescope-nvim
      telescope-file-browser-nvim
      barbar-nvim
      nvim-autopairs
      cord-nvim
      lazygit-nvim
      plenary-nvim
      trouble-nvim
      diffview-nvim
      toggleterm-nvim
    ];

    extraConfigLua = ''
      require("transparent").setup({})
      require("nvim-autopairs").setup({})
      require("nvim-tree").setup({})
      require("lualine").setup({})
      require("barbar").setup({})
      require("toggleterm").setup({
        size = 100,
        open_mapping = [[<c-t>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        close_on_exit = true,
      })
      require("trouble").setup({})
      require("cord").setup({})

      vim.cmd("colorscheme kipferl")
      vim.cmd([[
        highlight Normal guibg=none
        highlight NonText guibg=none
        highlight Normal ctermbg=none
        highlight NonText ctermbg=none
        highlight NormalNC guibg=none
        highlight NormalSB guibg=none
      ]])

      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "vsnip" },
        }, {
          { name = "buffer" },
        }),
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
        matching = { disallow_symbol_nonprefix_matching = false },
      })

      vim.keymap.set("n", "<C-q>", "<cmd>NvimTreeToggle<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<A-,>", "<cmd>BufferPrevious<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<A-.>", "<cmd>BufferNext<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<A-c>", "<cmd>BufferClose<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>g", "<cmd>LazyGit<CR>", { noremap = true, silent = true })
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
    '';
  };
}
