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
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
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
}
