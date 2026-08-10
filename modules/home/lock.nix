{
  flake.homeModules.lock =
    { ... }:
    {
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
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 300;                       # 5 minutes
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 330;                       # +30s: turn the display off
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
}
