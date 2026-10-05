{ pkgs, ... }:
let
  # ── treesitter: nvim-treesitter を使わず、パーサとクエリを Nix で固定する ──
  # Neovim 0.12 は tree-sitter をコアに統合済み（nvim-treesitter は archived）。
  # ハイライトは vim.treesitter.start() が runtimepath の parser/ と queries/ を
  # 探すので、ここで固定した言語は完全にオフラインで動く。
  # 未収録の言語は tree-sitter-manager 側で実行時に入れる（下の extraConfigLua）。
  tsLangs = [
    "bash"
    "c"
    "cpp"
    "diff"
    "gitcommit"
    "javascript"
    "json"
    "lua"
    "make"
    "markdown"
    "markdown_inline"
    "nix"
    "python"
    "query"
    "regex"
    "rust"
    "toml"
    "typescript"
    "vim"
    "vimdoc"
    "yaml"
  ];
  tsGrammars = map (l: pkgs.vimPlugins.nvim-treesitter-parsers.${l}) tsLangs;
  tsQueries = map (l: pkgs.vimPlugins.nvim-treesitter.queries.${l}) tsLangs;

  # ── tree-sitter-manager.nvim（nixvim にモジュールが無いので自前で固定） ──
  tree-sitter-manager = pkgs.vimUtils.buildVimPlugin {
    name = "tree-sitter-manager.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "romus204";
      repo = "tree-sitter-manager.nvim";
      rev = "d93782393d7d4b48ddbdbcb0fdff6f8cb8d7043a";
      hash = "sha256-OYxgK9A0QhyaXsQEFfa5VzYRpRx4Hcwk/0NImGjdIrM=";
    };
  };
in
{
  home.packages = with pkgs; [
    lazygit
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    # nixvim は nixpkgs.source から独自に pkgs を作る（NixOS 側の nixpkgs.config は
    # 引き継がれない）ため、allowUnfree 等を共有ファイルから渡す。
    nixpkgs = {
      source = pkgs.path;
      config = import ../../nixpkgs-config.nix;
    };
    viAlias = true;
    vimAlias = true;

    # tree-sitter-manager が parser を clone/ビルドするのに必要
    extraPackages = with pkgs; [
      gcc
      git
      tree-sitter
    ];

    globals = {
      mapleader = " ";
      maplocalleader = "\\";
      barbar_auto_setup = false;
    };

    opts = {
      pumheight = 10;
      termguicolors = true;
      winblend = 0;
      pumblend = 0;
    };

    colorschemes.dracula-nvim = {
      enable = true;
      settings = {
        transparent = true;
        style = "default";
        styles = {
          comments = {
            italic = true;
          };
          keywords = {
            bold = true;
          };
          functions = {
            bold = true;
          };
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<C-q>";
        action = "<cmd>NvimTreeToggle<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<A-,>";
        action = "<cmd>BufferPrevious<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<A-.>";
        action = "<cmd>BufferNext<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<A-c>";
        action = "<cmd>BufferClose<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<leader>g";
        action = "<cmd>LazyGit<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<leader>fd";
        action = "<cmd>Telescope diagnostics<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<CR>";
        options.silent = true;
      }
      {
        mode = "t";
        key = "<Esc>";
        action = "<C-\\><C-n>";
      }
    ];

    plugins = {
      transparent.enable = true;
      web-devicons.enable = true;

      # ── LSP ────────────────────────────────────────────────
      lsp = {
        enable = true;

        # cmp の補完能力を LSP クライアントに伝える
        # （plugins.cmp.autoEnableSources = false のため自動では入らない）
        capabilities = ''
          capabilities = vim.tbl_deep_extend("force", capabilities, require('cmp_nvim_lsp').default_capabilities())
        '';

        keymaps = {
          silent = true;
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gr" = "references";
            "gI" = "implementation";
            "gt" = "type_definition";
            "K" = "hover";
            "<leader>rn" = "rename";
            "<leader>ca" = "code_action";
          };
          diagnostic = {
            "[d" = "goto_prev";
            "]d" = "goto_next";
            "<leader>d" = "open_float";
          };
        };

        servers = {
          nixd = {
            enable = true;
            # nixvim が settings を { nixd = ... } で包むのでルートキーは書かない
            settings = {
              nixpkgs.expr = "import (builtins.getFlake \"/home/spring/dotfiles/nixos-config\").inputs.nixpkgs { }";
              formatting.command = [ "nixfmt" ];
              # リポジトリのオプション補完を使いたい場合は以下を有効化（評価が重い）
              # options = {
              #   nixos.expr = "(builtins.getFlake \"/home/spring/dotfiles/nixos-config\").nixosConfigurations.spring-t14-gen6.options";
              #   home-manager.expr = "(builtins.getFlake \"/home/spring/dotfiles/nixos-config\").nixosConfigurations.spring-t14-gen6.options.home-manager.users.spring";
              # };
            };
          };
          lua_ls = {
            enable = true;
            # nixvim が settings を { Lua = ... } で包むのでルートキーは書かない
            settings = {
              runtime.version = "LuaJIT";
              workspace.checkThirdParty = false;
              diagnostics.globals = [ "vim" ];
              telemetry.enable = false;
              hint.enable = true;
            };
          };
        };
      };
      lspkind.enable = true;
      fidget.enable = true;

      # ── 補完 ───────────────────────────────────────────────
      cmp = {
        enable = true;
        autoEnableSources = false;
        settings = {
          snippet.expand.__raw = ''
            function(args)
              vim.fn["vsnip#anonymous"](args.body)
            end
          '';
          mapping.__raw = ''
            cmp.mapping.preset.insert({
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
            })
          '';
          sources.__raw = ''
            cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "vsnip" },
            }, {
              { name = "buffer" },
            })
          '';
        };
        cmdline = {
          "/" = {
            mapping.__raw = "cmp.mapping.preset.cmdline()";
            sources = [ { name = "buffer"; } ];
          };
          "?" = {
            mapping.__raw = "cmp.mapping.preset.cmdline()";
            sources = [ { name = "buffer"; } ];
          };
          ":" = {
            mapping.__raw = "cmp.mapping.preset.cmdline()";
            sources.__raw = ''
              cmp.config.sources({
                { name = "path" },
              }, {
                { name = "cmdline" },
              })
            '';
            matching.disallow_symbol_nonprefix_matching = false;
          };
        };
      };
      cmp-nvim-lsp.enable = true;
      cmp-buffer.enable = true;
      cmp-path.enable = true;
      cmp-cmdline.enable = true;
      cmp-vsnip.enable = true;

      # ── UI / 操作 ──────────────────────────────────────────
      nvim-tree.enable = true;
      lualine = {
        enable = true;
        settings.options.theme = "dracula-nvim";
      };
      telescope = {
        enable = true;
        extensions.file-browser.enable = true;
      };
      barbar.enable = true;
      nvim-autopairs.enable = true;
      cord.enable = true;
      lazygit.enable = true;
      trouble.enable = true;
      diffview.enable = true;
      toggleterm = {
        enable = true;
        settings = {
          size = 100;
          open_mapping = "[[<c-t>]]";
          hide_numbers = true;
          shade_terminals = true;
          shading_factor = 2;
          start_in_insert = true;
          insert_mappings = true;
          close_on_exit = true;
        };
      };
    };

    extraPlugins = [
      tree-sitter-manager
      pkgs.vimPlugins.vim-vsnip
    ]
    ++ tsGrammars
    ++ tsQueries;

    extraConfigLua = ''
      -- ── treesitter ─────────────────────────────────────────
      -- Nix で固定した言語は runtimepath の parser/ と queries/ から読まれる。
      -- ハイライトの有効化は tree-sitter-manager の FileType autocmd
      -- （highlight = true）が全言語に対して行う。
      require("tree-sitter-manager").setup({
        -- Nix 側で固定済みの言語はマネージャの管理対象から外す
        assume_installed = {
          "bash", "c", "cpp", "diff", "gitcommit", "javascript", "json",
          "lua", "make", "markdown", "markdown_inline", "nix", "python",
          "query", "regex", "rust", "toml", "typescript", "vim", "vimdoc", "yaml",
        },
        highlight = true,
        auto_install = false,
      })
    '';
  };
}
