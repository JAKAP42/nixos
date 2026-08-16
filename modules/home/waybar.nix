{
  flake.homeModules.waybar =
    { ... }:
    {
      # Neutral translucent-black "floating bubble" bar. We turn OFF Stylix's
      # waybar target so it doesn't fight our custom CSS below; the colors here
      # are deliberately theme-independent (blackish + a little transparency).
      stylix.targets.waybar.enable = false;

      programs.waybar = {
        enable = true;
        # Launched from the Hyprland config instead (systemd wiring was unreliable).
        systemd.enable = false;
        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 36;
          spacing = 4;
          # Pull the whole bar in from the screen edges a little; combined with the
          # transparent window background this creates the detached, floating look.
          margin-top = 6;
          margin-left = 8;
          margin-right = 8;

          modules-left = [ "hyprland/workspaces" "hyprland/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "battery" "tray" ];

          "hyprland/workspaces" = {
            format = "{id}";
            on-click = "activate";
          };
          "hyprland/window".max-length = 60;

          clock = {
            # %V = ISO week number of the year. Shown as "v.32" (v = vecka/week).
            format = "{:%a %d %b  v.%V  %H:%M}";
            # The calendar shows as a tooltip when you hover the clock.
            tooltip-format = "<tt>{calendar}</tt>";
            calendar = {
              mode = "month";
              # Show week numbers down the left side of the calendar too.
              weeks-pos = "left";
              on-scroll = 1;
              format = {
                # Highlight today; keeps Stylix's theme colors otherwise.
                today = "<b><u>{}</u></b>";
                weeks = "<b>v{}</b>";
              };
            };
            actions = {
              # Right-click toggles month <-> year view; scroll changes months.
              on-click-right = "mode";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };

          battery = {
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ";
            format-icons = [ "" "" "" "" "" ];
          };

          network = {
            format-wifi = "  {essid}";
            format-ethernet = "  wired";
            format-disconnected = "  offline";
            tooltip-format = "{ifname}: {ipaddr}";
            # Quick connect/scan lives on the nm-applet tray icon next to this pill;
            # clicking the pill itself opens the full connection settings GUI.
            on-click = "nm-connection-editor";
          };

          pulseaudio = {
            format = "{volume}% {icon}";
            format-muted = " muted";
            format-icons.default = [ "" "" "" ];
            on-click = "pavucontrol";
          };

          tray.spacing = 8;
        };

        # Each module group is drawn as its own rounded, semi-transparent black
        # pill floating over the wallpaper. Text is a soft off-white so it reads
        # over any background. No Stylix accent colors here, on purpose.
        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", "Noto Sans", sans-serif;
            font-size: 13px;
            border: none;
            min-height: 0;
          }

          /* The bar itself is invisible; only the pills below are drawn. */
          window#waybar {
            background: transparent;
          }

          /* The floating translucent-black pills. */
          #workspaces,
          #clock,
          #pulseaudio,
          #network,
          #battery,
          #tray {
            background-color: rgba(0, 0, 0, 0.40);
            color: #eaeaea;
            padding: 2px 12px;
            margin: 4px 4px;
            border-radius: 14px;
          }

          /* The window title floats without its own pill so it stays subtle. */
          #window {
            color: #eaeaea;
            padding: 0 10px;
            margin: 4px 4px;
          }

          /* Workspace numbers live inside the workspaces pill. */
          #workspaces button {
            color: #bcbcbc;
            padding: 0 6px;
            border-radius: 10px;
          }
          #workspaces button.active {
            background-color: rgba(255, 255, 255, 0.18);
            color: #ffffff;
          }
          #workspaces button:hover {
            background-color: rgba(255, 255, 255, 0.10);
            color: #ffffff;
          }

          /* Only shout in color when the battery is actually critical. */
          #battery.critical:not(.charging) {
            color: #ff6b6b;
          }
        '';
      };
    };
}
