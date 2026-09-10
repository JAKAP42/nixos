{
  flake.homeModules.waybar =
    { pkgs, ... }:
    {
      # Opened by the volume module's click action below. (The network module
      # clicks `nm-connection-editor`, which ships with networkmanagerapplet in
      # modules/home/hyprland.nix, alongside the nm-applet it execs at startup.)
      home.packages = [ pkgs.pavucontrol ];

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
          modules-right = [ "custom/gsr" "pulseaudio" "bluetooth" "network" "battery" "tray" ];

          "hyprland/workspaces" = {
            format = "{id}";
            on-click = "activate";
          };
          "hyprland/window".max-length = 60;

          clock = {
            # %V = ISO week number of the year. Shown as "v.32" (v = vecka/week).
            format = "{:%a %d %b  week.%V  %H:%M}";
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

          bluetooth = {
            # No pill text when nothing is connected -- just the icon, so the bar
            # stays quiet until a device is actually in use.
            format = "";
            format-connected = "  {device_alias}";
            format-connected-battery = "  {device_alias} {device_battery_percentage}%";
            format-off = "";
            format-disabled = "";
            tooltip-format = "{controller_alias} ({status})";
            tooltip-format-connected = "{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}";
            tooltip-format-enumerate-connected-battery = "{device_alias} — {device_battery_percentage}%";
            # Same split as the network pill: the tray applet handles quick
            # connects, clicking the pill opens the full pairing manager.
            on-click = "blueman-manager";
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

          # Red REC pill, shown only while GPU Screen Recorder is actually
          # running (SUPER+ALT+F toggles it). `gsr-waybar` prints an empty text
          # when idle, which makes waybar hide the module entirely, so the bar
          # stays quiet the rest of the time — same idea as the bluetooth pill.
          "custom/gsr" = {
            exec = "gsr-waybar"; # from modules/home/gpu-screen-recorder.nix
            return-type = "json";
            # The keybind signals waybar directly so the pill appears the moment
            # recording starts; the interval is just a safety net that clears it
            # if the recorder ever exits on its own. Keep this number in step
            # with `refreshBar` in modules/home/gpu-screen-recorder.nix.
            signal = 8;
            interval = 5;
            # Clicking the pill stops and saves, for when the keybind isn't handy.
            on-click = "gsr-toggle";
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
          #bluetooth,
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

          /* The recording indicator. Styled only in its .recording state, so
             the idle module draws no pill at all. The slow pulse is there to
             catch the corner of your eye — a static dot is easy to forget
             about and end up with an hour-long file. */
          #custom-gsr.recording {
            background-color: rgba(0, 0, 0, 0.40);
            color: #ff5f5f;
            padding: 2px 12px;
            margin: 4px 4px;
            border-radius: 14px;
            animation: gsr-pulse 2s ease-in-out infinite alternate;
          }

          @keyframes gsr-pulse {
            from { color: #ff5f5f; }
            to   { color: #7a2020; }
          }
        '';
      };
    };
}
