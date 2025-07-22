{ config, pkgs, inputs, lib, ... }:
{
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    
    # Colorscheme
    colorschemes.catppuccin.enable = true;
    
    # Built-in plugins
    plugins = {
      lualine.enable = true;
      nvim-tree.enable = true;
      web-devicons.enable = true;
      
      telescope = {
        enable = true;
        keymaps = {
          "<leader>t" = "live_grep";
        };
      };
      
      treesitter = {
        enable = true;
        settings = {
          auto_install = true;
          highlight.enable = true;
          indent.enable = true;
        };
      };
      
      nvim-autopairs.enable = true;

      bufferline = {
        enable = true;
        settings = {
          options = {
            separator_style = "slant";
            show_buffer_close_icons = true;
            show_close_icon = true;
            enforce_regular_tabs = false;
            always_show_bufferline = true;
            diagnostics = "nvim_lsp";
            offsets = [
              {
                filetype = "NvimTree";
                text = "File Explorer";
                highlight = "Directory";
                text_align = "left";
              }
            ];
          };
        };
      };
    };
    
    # Extra plugins not available as built-in
    extraPlugins = with pkgs.vimPlugins; [
      vim-easymotion
      vim-surround
      vim-nix
      vim-terraform
      lightline-bufferline
    ];
    
    keymaps = [
      {
        mode = "n";
        key = "<leader>f";
        action = "<Plug>(easymotion-overwin-f)";
      }
      {
        mode = "n";
        key = "<Tab>";
        action = "<Cmd>BufferLineCycleNext<CR>";
      }
      {
        mode = "n";
        key = "<S-Tab>";
        action = "<Cmd>BufferLineCyclePrev<CR>";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = "<Cmd>bd<CR>";
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = "<Cmd>BufferLinePick<CR>";
      }
      {
        mode = "n";
        key = "<leader>mp";
        action = "<Cmd>silent !pandoc % -s -o /tmp/preview.html && xdg-open /tmp/preview.html &<CR>";
      }
    ];

    extraConfigLua = ''
      -- vim-markdown-composer settings
      vim.g.markdown_composer_browser = 'brave'
      vim.g.markdown_composer_open_browser = 0  -- Don't auto-open
      vim.g.markdown_composer_refresh_rate = 0  -- Realtime updates
      vim.g.markdown_composer_syntax_theme = 'github-dark'
    '';

    opts = {
      number = true;
      shiftwidth = 2;
      smartindent = true;
      autoindent = true;
      swapfile = false;
      splitbelow = true;
      splitright = true;
    };
  };
}
