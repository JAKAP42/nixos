{
  flake.homeModules.waybar =
    { ... }:
    {
      # Colors and fonts come from Stylix's waybar target automatically, so this
      # only defines the layout and module content.
      programs.waybar = {
        enable = true;
        # Launched from the Hyprland config instead (systemd wiring was unreliable).
        systemd.enable = false;
        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 36;
          spacing = 6;

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
          };

          pulseaudio = {
            format = "{volume}% {icon}";
            format-muted = " muted";
            format-icons.default = [ "" "" "" ];
            on-click = "pavucontrol";
          };

          tray.spacing = 8;
        };
      };
    };
}
