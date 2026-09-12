{
  flake.homeModules.waybar =
    { pkgs, ... }:
    let
      # The month-at-a-time calendar that clicking the clock opens, with the
      # arrow buttons GTK's calendar widget draws in its header for stepping
      # month and year. That header is the whole point of this script.
      #
      # waybar's own calendar can only ever be a hover tooltip, and tooltips
      # are not interactive: you cannot put a button in one. Its navigation is
      # therefore scroll-only, which is awkward on a touchpad, and its year
      # mode renders all twelve months as one tall block that runs off the
      # bottom of a 720pt-tall screen. A real window sidesteps both.
      #
      # yad is a thin wrapper around stock GTK dialogs, so `--calendar` is
      # literally a GtkCalendar: clickable arrows, keyboard arrows, and week
      # numbers via --show-weeks (matching the %V in the bar's own format).
      # Hyprland floats and places the window -- see the `waybar-calendar`
      # window_rule in modules/home/hyprland.nix, which pins its size to the
      # 300x240 assumed there.
      #
      # Clicking the clock a second time closes it, which needs the script to
      # know whether one is already open. That question is answered by PID in a
      # runtime state file rather than by matching on process name, for the
      # reasons written up at length in modules/home/gpu-screen-recorder.nix:
      # `pkill -f yad` would take out any other yad dialog on the desktop. The
      # file is self-healing -- if the window was closed with Escape instead,
      # the recorded PID stops responding and the next click just opens a fresh
      # one.
      calendar = pkgs.writeShellApplication {
        name = "waybar-calendar";
        runtimeInputs = with pkgs; [
          yad
          coreutils # cat, rm
        ];
        text = ''
          state="''${XDG_RUNTIME_DIR:-/tmp}/waybar-calendar.pid"

          if [ -r "$state" ]; then
              read -r pid < "$state" || pid=""
              case "$pid" in "" | *[!0-9]*) pid="" ;; esac

              # Guards against the PID having been recycled by an unrelated
              # process since we wrote it. This compares /proc/<pid>/exe and
              # not /proc/<pid>/comm, which is the obvious way to write it and
              # is wrong: nixpkgs wraps yad, so `exec yad` below lands on
              # `.yad-wrapped` and that, not "yad", is the name the kernel
              # stores. Matching on the name therefore never fires, and the
              # failure is silent and confusing -- clicking the clock a second
              # time opens another calendar on top of the first instead of
              # closing it. The store path has no such ambiguity.
              exe=""
              if [ -n "$pid" ]; then
                  exe=$(readlink -f /proc/"$pid"/exe 2> /dev/null || true)
              fi

              case "$exe" in
                  ${pkgs.yad}/*)
                      kill "$pid"
                      rm -f "$state"
                      exit 0
                      ;;
              esac
              rm -f "$state"
          fi

          # $$ is the PID yad will have, because of the exec below.
          printf '%s\n' "$$" > "$state"

          # GTK reads the first day of the week from LC_TIME, and the session's
          # en_US would start it on Sunday -- which shifts every week number in
          # the column below one day off the ISO %V the bar prints above it.
          # en_GB is Monday-first and ISO-numbered with English month names, so
          # this is the whole change; see i18n.supportedLocales in
          # modules/base.nix, which is what generates it.
          export LC_TIME=en_GB.UTF-8

          # --no-buttons because there is nothing to confirm; this is a thing to
          # look at, not a date picker. Escape closes it either way.
          exec yad --calendar \
              --title=waybar-calendar \
              --show-weeks \
              --undecorated \
              --no-buttons \
              --skip-taskbar \
              --borders=0 \
              --width=300 --height=240
        '';
      };
    in
    {
      # pavucontrol is opened by the volume module's click action below, and
      # waybar-calendar by the clock's. (The network module clicks
      # `nm-connection-editor`, which ships with networkmanagerapplet in
      # modules/home/hyprland.nix, alongside the nm-applet it execs at startup.)
      home.packages = [
        pkgs.pavucontrol
        calendar
      ];

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
            # No hover tooltip. waybar's built-in calendar would render one
            # here, but the click action below opens a better one, and having
            # both means the tooltip pops up over the window you just opened
            # every time the pointer crosses the clock. There is only one
            # calendar now, and it is the one you ask for.
            tooltip = false;
            # Opens the clickable month-by-month calendar; clicking again closes
            # it. Not an entry under `actions` -- that map takes waybar's own
            # action names, this is a command to run.
            on-click = "waybar-calendar";
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
