{
  flake.homeModules.lock =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # Stylix hands hyprlock a 1x1 solid-colour pixel as its background, so the
      # lock screen is a flat wall of base00. Give it a real picture instead,
      # drawn at random from the same folder waypaper uses for the desktop --
      # so every lock looks like a fresh wallpaper.
      #
      # hyprlock's background path is fixed at config-read time, and the config
      # home-manager generates is a read-only store symlink. So: copy that
      # generated config, swap the path in its background block for a random
      # image, and point hyprlock at the copy with -c. Everything else Stylix
      # themed (colours, fonts, input field) is preserved verbatim.
      hyprlockRandom = pkgs.writeShellScriptBin "hyprlock-random" ''
        export PATH=${
          lib.makeBinPath [
            config.programs.hyprlock.package
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnused
            pkgs.gawk
          ]
        }:$PATH

        conf="$HOME/.config/hypr/hyprlock.conf"

        folder=$(sed -n 's/^folder *= *//p' "$HOME/.config/waypaper/config.ini" \
                 2>/dev/null | head -n1)
        folder=''${folder/#\~/$HOME}
        [ -n "$folder" ] || folder="$HOME/Desktop/wallpapers"

        img=$(find "$folder" -maxdepth 1 -type f \
              \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
              -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.bmp' \) \
              2>/dev/null | shuf -n1)

        # No images, or no generated config to patch: still lock, just with the
        # plain Stylix background. Never leave the session unlocked.
        if [ -z "$img" ] || [ ! -r "$conf" ]; then
          exec hyprlock "$@"
        fi

        out="''${XDG_RUNTIME_DIR:-/tmp}/hyprlock-random.conf"
        awk -v img="$img" '
          /^[[:space:]]*background[[:space:]]*\{/ { inbg = 1; seen = 0; print; next }
          inbg && /^[[:space:]]*path[[:space:]]*=/ { print "  path=" img; seen = 1; next }
          inbg && /^[[:space:]]*\}/ { if (!seen) print "  path=" img; inbg = 0; print; next }
          { print }
        ' "$conf" > "$out"

        exec hyprlock -c "$out" "$@"
      '';
    in
    {
      # On PATH so the Hyprland keybind (Super+Escape) can call it by name.
      home.packages = [ hyprlockRandom ];

      # Screen locker. Stylix themes the background/input colors; this sets layout.
      programs.hyprlock = {
        enable = true;
        # Background + input-field colors/layout are provided by Stylix's hyprlock
        # target. Only behavior is set here.
        settings = {
          general = {
            hide_cursor = true;
            grace = 2;          # seconds after locking where a key/mouse cancels
          };
        };
      };

      # Idle daemon: lock after 5 min, blank screen 30s later, lock before sleep.
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || ${hyprlockRandom}/bin/hyprlock-random";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 1200;                       # 5 minutes
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 1380;                       # +30s: turn the display off
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
}
