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
      markdown-preview-nvim
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
        key = "<leader>p";
        action = "<Cmd>:MarkdownPreviewToggle<CR>";
      }
    ];

        # Plugin-specific Lua configuration
    extraConfigLua = ''
      -- markdown-preview.nvim settings
      vim.g.mkdp_auto_start = 0    -- do not automatically open
      vim.g.mkdp_auto_close = 1    -- close with buffer
      vim.g.mkdp_filetypes  = { "markdown" }
      vim.g.mkdp_browser    = "brave"
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
  system.activationScripts.markdownPreviewInstall = ''
    echo "Installing markdown-preview-nvim dependencies…"
    ${config.programs.nixvim.package}/bin/nvim \
      --headless \
      +"call mkdp#util#install()" \
      +qa
  '';
}
