# Neovim: a hand-rolled config rather than a distro (LazyVim, NvChad, ...).
#
# Everything lives in this one file: the plugin list comes from pkgs.vimPlugins,
# so plugins are pinned by flake.lock and roll back with `nixos-rebuild` like the
# rest of the system. There is no lazy.nvim, no lock file of its own, and nothing
# to `:PluginUpdate` -- to change anything here, edit this file and rebuild.
#
# The trade-off: adding a plugin costs a rebuild instead of a `:Lazy install`.
# In exchange there is exactly one update mechanism for the whole machine.
#
# Colors come from Stylix (catppuccin-mocha, same as kitty and waybar), so this
# file sets no colorscheme. See the transparency note further down.
{
  flake.homeModules.neovim =
    { pkgs, config, ... }:
    {
      # Stylix themes Neovim through mini.base16 and appends that block to the
      # end of init.lua, after everything below. These three switches make it
      # emit `highlight Normal guibg=NONE` (and friends) at the very end, so the
      # editor background falls through to kitty's translucency.
      #
      # Floating windows -- Telescope, the completion popup, the neo-tree
      # sidebar -- deliberately keep their solid background, so panels read as
      # panels instead of dissolving into the wallpaper.
      stylix.targets.neovim.transparentBackground = {
        main = true;
        signColumn = true;
        numberLine = true;
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;

        # Tools the plugins shell out to. These are wrapped into the neovim
        # package itself, so they are on PATH for nvim without polluting the
        # user profile.
        extraPackages = with pkgs; [
          ripgrep # telescope live_grep
          fd # telescope find_files
          wl-clipboard # makes clipboard=unnamedplus reach the Wayland clipboard
          kitty # for `kitten @`, used by the opacity switch below

          # Language servers. Nix installs them, so there is no mason.nvim here
          # and nothing downloads binaries at runtime.
          nixd # .nix
          lua-language-server # .lua  (hyprland/waybar configs)
          basedpyright # .py
          nixfmt # formatter nixd calls (the RFC-style one; the old
          # nixfmt-rfc-style attribute is now just an alias)
        ];

        plugins = with pkgs.vimPlugins; [
          # -- dependencies shared by several plugins below
          plenary-nvim
          nui-nvim
          nvim-web-devicons

          # -- navigation
          neo-tree-nvim
          telescope-nvim
          telescope-fzf-native-nvim # native sorter; compiled by Nix, not at runtime

          # -- syntax. withAllGrammars ships every parser prebuilt, so no
          #    :TSInstall step and no compiler needed at runtime.
          nvim-treesitter.withAllGrammars

          # -- LSP + completion
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          cmp_luasnip
          luasnip

          # -- editing quality of life
          comment-nvim
          nvim-autopairs
          indent-blankline-nvim

          # -- UI
          lualine-nvim
          bufferline-nvim
          gitsigns-nvim
          which-key-nvim
        ];

        # Stylix's colorscheme block is appended after this (home-manager gives
        # plugin-generated config a later order), which is what we want: its
        # transparency highlights must land last to win.
        initLua = ''
          -- ==========================================================
          -- Leader. Must be set before any plugin reads a mapping.
          -- Space, because the default \ needs AltGr on a Norwegian layout.
          -- ==========================================================
          vim.g.mapleader = " "
          vim.g.maplocalleader = " "

          -- ==========================================================
          -- Options
          -- ==========================================================
          local o = vim.o
          o.number = true
          o.relativenumber = true          -- jump N lines with 5j / 5k
          o.mouse = "a"
          o.clipboard = "unnamedplus"      -- y and p use the system clipboard
          o.expandtab = true               -- spaces, matching the .nix files here
          o.shiftwidth = 2
          o.tabstop = 2
          o.softtabstop = 2
          o.smartindent = true
          o.wrap = false
          o.ignorecase = true
          o.smartcase = true               -- ...unless the search has a capital
          o.signcolumn = "yes"             -- always on, so text doesn't jump
          o.updatetime = 250
          o.timeoutlen = 400               -- how long which-key waits before popping up
          o.splitright = true
          o.splitbelow = true
          o.scrolloff = 8
          o.cursorline = true
          o.undofile = true                -- undo survives closing the file
          o.confirm = true                 -- ask instead of failing on :q with changes
          o.termguicolors = true

          -- ==========================================================
          -- Treesitter
          --
          -- nixpkgs ships the rewritten "main" branch of nvim-treesitter, which
          -- dropped the old require("nvim-treesitter.configs").setup{} entry
          -- point that most tutorials still use. Highlighting is started per
          -- buffer instead, which is what this autocmd does.
          -- ==========================================================
          require("nvim-treesitter").setup()

          vim.api.nvim_create_autocmd("FileType", {
            desc = "Enable treesitter highlighting when a parser exists",
            callback = function(ev)
              local ft = vim.bo[ev.buf].filetype
              local lang = vim.treesitter.language.get_lang(ft) or ft
              -- pcall: filetypes with no parser (mail, help pages) fall back to
              -- regex highlighting instead of throwing on every buffer open.
              if pcall(vim.treesitter.start, ev.buf, lang) then
                vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              end
            end,
          })

          -- ==========================================================
          -- LSP
          --
          -- Neovim 0.12 resolves server definitions from nvim-lspconfig's lsp/
          -- directory, so vim.lsp.enable(name) is the whole setup. No
          -- lspconfig.setup{} calls, no mason.
          -- ==========================================================

          -- Advertise nvim-cmp's extra capabilities to every server.
          vim.lsp.config("*", {
            capabilities = require("cmp_nvim_lsp").default_capabilities(),
          })

          vim.lsp.config("nixd", {
            settings = {
              nixd = {
                formatting = { command = { "nixfmt" } };
              },
            },
          })

          vim.lsp.config("lua_ls", {
            settings = {
              Lua = {
                -- Stop it complaining that `vim` is undefined in this very file.
                diagnostics = { globals = { "vim" } },
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
              },
            },
          })

          vim.lsp.enable({ "nixd", "lua_ls", "basedpyright" })

          vim.diagnostic.config({
            virtual_text = { spacing = 2, prefix = "●" },
            severity_sort = true,
            float = { border = "rounded", source = true },
            signs = {
              text = {
                [vim.diagnostic.severity.ERROR] = "󰅚 ",
                [vim.diagnostic.severity.WARN]  = "󰀪 ",
                [vim.diagnostic.severity.INFO]  = "󰋽 ",
                [vim.diagnostic.severity.HINT]  = "󰌶 ",
              },
            },
          })

          -- LSP keymaps, bound only in buffers where a server actually attached.
          vim.api.nvim_create_autocmd("LspAttach", {
            desc = "LSP keymaps",
            callback = function(ev)
              local function map(keys, fn, desc)
                vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
              end
              map("gd", vim.lsp.buf.definition, "Go to definition")
              map("gD", vim.lsp.buf.declaration, "Go to declaration")
              map("gr", require("telescope.builtin").lsp_references, "References")
              map("gi", vim.lsp.buf.implementation, "Go to implementation")
              map("K",  vim.lsp.buf.hover, "Hover docs")
              map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
              map("<leader>ca", vim.lsp.buf.code_action, "Code action")
              map("<leader>fm", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
            end,
          })

          -- ==========================================================
          -- Completion
          -- ==========================================================
          local cmp = require("cmp")
          local luasnip = require("luasnip")

          cmp.setup({
            snippet = {
              expand = function(args) luasnip.lsp_expand(args.body) end,
            },
            mapping = cmp.mapping.preset.insert({
              ["<C-Space>"] = cmp.mapping.complete(),
              ["<C-e>"]     = cmp.mapping.abort(),
              -- select = false: Enter only accepts an item you actually picked,
              -- so it still inserts a newline when the menu is merely open.
              ["<CR>"]      = cmp.mapping.confirm({ select = false }),
              ["<Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then cmp.select_next_item()
                elseif luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump()
                else fallback() end
              end, { "i", "s" }),
              ["<S-Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then cmp.select_prev_item()
                elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
                else fallback() end
              end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "luasnip" },
            }, {
              { name = "buffer" },
              { name = "path" },
            }),
          })

          -- Insert the closing bracket when a completed function is accepted.
          cmp.event:on(
            "confirm_done",
            require("nvim-autopairs.completion.cmp").on_confirm_done()
          )

          -- ==========================================================
          -- Plugin setup
          -- ==========================================================
          require("neo-tree").setup({
            close_if_last_window = true,
            filesystem = {
              follow_current_file = { enabled = true },   -- sidebar tracks the open buffer
              use_libuv_file_watcher = true,              -- refresh without :e
              filtered_items = {
                hide_dotfiles = false,                    -- .config, .gitignore etc. matter here
                hide_gitignored = true,
              },
            },
            window = { width = 32 },
          })

          local telescope = require("telescope")
          telescope.setup({
            defaults = {
              layout_strategy = "flex",
              path_display = { "truncate" },
            },
          })
          pcall(telescope.load_extension, "fzf")

          require("gitsigns").setup()
          require("Comment").setup()
          require("nvim-autopairs").setup({})
          require("ibl").setup({ scope = { enabled = false } })
          require("which-key").setup({})

          require("lualine").setup({
            options = {
              -- Stylix owns the palette; "auto" derives the bar from it.
              theme = "auto",
              globalstatus = true,
              section_separators = "",
              component_separators = "|",
            },
          })

          require("bufferline").setup({
            options = {
              diagnostics = "nvim_lsp",
              offsets = {
                { filetype = "neo-tree", text = "Files", separator = true },
              },
            },
          })

          -- ==========================================================
          -- Keymaps
          --
          -- Chosen to avoid AltGr on a Norwegian layout: no [ ] { } \ | in any
          -- binding. That rules out the conventional ]d / [d and ]c / [c pairs,
          -- so diagnostics and git hunks are on leader keys and buffers move
          -- with Alt+arrows.
          -- ==========================================================
          local map = vim.keymap.set

          -- files
          map("n", "<leader>e", "<cmd>Neotree toggle<cr>",        { desc = "File tree: toggle" })
          map("n", "<leader>o", "<cmd>Neotree focus<cr>",         { desc = "File tree: focus" })

          -- find (telescope)
          local tb = require("telescope.builtin")
          map("n", "<leader>ff", tb.find_files,  { desc = "Find: files" })
          map("n", "<leader>fg", tb.live_grep,   { desc = "Find: grep in project" })
          map("n", "<leader>fb", tb.buffers,     { desc = "Find: open buffers" })
          map("n", "<leader>fh", tb.help_tags,   { desc = "Find: help" })
          map("n", "<leader>fr", tb.oldfiles,    { desc = "Find: recent files" })
          map("n", "<leader>fk", tb.keymaps,     { desc = "Find: keymaps" })

          -- buffers
          map("n", "<M-Right>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
          map("n", "<M-Left>",  "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
          map("n", "<leader>w", "<cmd>write<cr>",               { desc = "Write file" })
          map("n", "<leader>q", "<cmd>bdelete<cr>",             { desc = "Close buffer" })

          -- diagnostics (replaces ]d / [d)
          map("n", "<leader>d", function() vim.diagnostic.jump({ count = 1 }) end,  { desc = "Next diagnostic" })
          map("n", "<leader>D", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Previous diagnostic" })
          map("n", "<leader>l", vim.diagnostic.open_float, { desc = "Show diagnostic under cursor" })
          map("n", "<leader>fd", tb.diagnostics, { desc = "Find: diagnostics" })

          -- git hunks (replaces ]c / [c)
          local gs = require("gitsigns")
          map("n", "<leader>gj", function() gs.nav_hunk("next") end, { desc = "Git: next hunk" })
          map("n", "<leader>gk", function() gs.nav_hunk("prev") end, { desc = "Git: previous hunk" })
          map("n", "<leader>gp", gs.preview_hunk,                    { desc = "Git: preview hunk" })
          map("n", "<leader>gb", gs.blame_line,                      { desc = "Git: blame line" })

          -- windows
          map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
          map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
          map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
          map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

          -- misc
          map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
          map("t", "<Esc><Esc>", "<C-\\><C-n>",    { desc = "Leave terminal mode" })

          -- ==========================================================
          -- Opacity handoff with kitty
          --
          -- Neovim has no background of its own -- Stylix clears it (see the
          -- transparentBackground options in this module) so kitty's shows
          -- through. But the shell and an editor want different amounts of
          -- see-through: 0.5 is fine for command output and washes out syntax
          -- comments, which sit at base03.
          --
          -- So kitty stays at the shell value and nvim borrows a higher one for
          -- as long as it is running. Needs dynamic_background_opacity and
          -- allow_remote_control in modules/home/kitty.nix.
          --
          -- Caveat: kitty applies opacity per OS window, not per split or tab.
          -- A shell sharing this window with nvim goes along for the ride.
          -- ==========================================================
          local editing_opacity = "0.85"
          -- Pulled from stylix.opacity.terminal so this can't drift out of sync
          -- with what kitty.nix actually sets.
          local shell_opacity = "${toString config.stylix.opacity.terminal}"

          local function set_kitty_opacity(value, blocking)
            -- KITTY_LISTEN_ON is only set when kitty has listen_on configured,
            -- so this no-ops in any other terminal rather than erroring.
            local socket = vim.env.KITTY_LISTEN_ON
            if not socket then return end
            local proc = vim.system(
              { "kitten", "@", "--to", socket, "set-background-opacity", value },
              { text = true }
            )
            -- On the way out we have to wait: nvim would otherwise exit before
            -- the request is written, stranding the terminal at editing opacity.
            if blocking then proc:wait(1000) end
          end

          vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
            desc = "Raise kitty opacity while editing",
            callback = function() set_kitty_opacity(editing_opacity, false) end,
          })

          vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
            desc = "Hand kitty's opacity back to the shell",
            callback = function() set_kitty_opacity(shell_opacity, true) end,
          })

          -- Briefly highlight what was just yanked.
          vim.api.nvim_create_autocmd("TextYankPost", {
            desc = "Highlight on yank",
            callback = function() vim.hl.on_yank() end,
          })
        '';
      };
    };
}
