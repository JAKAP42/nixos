{
  flake.homeModules.nwgDrawer =
    { ... }:
    {
      # nwg-drawer's only styling hook is a GTK CSS file it *reads* at launch
      # (it never writes to it), so a normal read-only home-manager symlink is
      # safe here — unlike waypaper, which needed a writable seed. This keeps the
      # drawer's look in the flake, so it reproduces on every machine.
      #
      # Sizes/columns/margins are NOT here — those are launch flags on the
      # `nwg-drawer` command in modules/home/hyprland.nix (`-is`, `-c`, `-mt`...).
      # Colours below use the Catppuccin Mocha palette to match Stylix.
      xdg.configFile."nwg-drawer/drawer.css".text = ''
        /* Fullscreen background layer. nwg-drawer is always fullscreen by design;
           the alpha (last number, 0=clear .. 1=solid) lets your desktop show
           through so it reads as icons floating over the screen. */
        window {
            background-color: rgba(30, 30, 46, 0.65);
            color: #cdd6f4;
        }

        /* Search box at the top */
        entry {
            background-color: rgba(49, 50, 68, 0.9);
            border: 1px solid #45475a;
            border-radius: 10px;
            color: #cdd6f4;
            padding: 6px 10px;
        }

        /* Each app tile */
        button {
            background: transparent;
            border: none;
            border-radius: 12px;
            padding: 6px;
        }
        button:hover {
            background-color: rgba(137, 180, 250, 0.25);  /* Catppuccin blue */
        }

        /* App name labels under the icons */
        label {
            color: #cdd6f4;
        }
    '';
    };
}
