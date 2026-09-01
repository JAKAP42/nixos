{
  flake.homeModules.hyprland =
    { pkgs, lib, ... }:
    let
      # Fallback wallpaper (shown only until waypaper restores your pick).
      wallpaper = "${pkgs.hyprland}/share/hypr/wall1.png";

      # Wallpaper at login. waypaper's picture folder lives on the ~/MEGA rclone
      # mount, which is still coming up when Hyprland starts. Called too early,
      # waypaper finds no images, falls back to the saved path (not there yet),
      # spawns a swaybg that fails to load it, and then kills the fallback
      # swaybg by PID -- leaving a black desktop. So: show the fallback, wait for
      # the folder to really contain images, then let waypaper take over. If it
      # never shows up (mount failed, no network), keep the fallback rather than
      # letting waypaper kill it.
      wallpaperStart = pkgs.writeShellScript "wallpaper-start" ''
        export PATH=${
          lib.makeBinPath [
            pkgs.swaybg
            pkgs.waypaper
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnused
          ]
        }:$PATH

        swaybg -i ${wallpaper} -m fill &

        folder=$(sed -n 's/^folder *= *//p' "$HOME/.config/waypaper/config.ini" | head -n1)
        folder=''${folder/#\~/$HOME}
        [ -n "$folder" ] || exit 0

        for _ in $(seq 60); do
          if [ -n "$(find "$folder" -maxdepth 1 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
                -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.bmp' \) \
                -print -quit 2>/dev/null)" ]; then
            exec waypaper --random
          fi
          sleep 1
        done
      '';
    in
    {
      # Hyprland 0.55 uses a real Lua config (hyprland.lua, the `hl.` API) — the old
      # hyprland.conf/hyprlang format is gone. Home-manager's settings->Lua
      # translator can't express the hl.dsp dispatchers, so instead of using
      # `settings` we hand-write correct Lua in `extraConfig`, which the module
      # appends verbatim. `systemd.enable = true` (default) injects the startup hook
      # that reaches graphical-session.target, which auto-starts waybar/mako/hypridle.
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";

        extraConfig = ''
          local mainMod  = "SUPER"
          local terminal = "kitty"
          local menu     = "nwg-drawer -is 32 -c 6"   -- full-screen big-icon app drawer

          -- Monitors: auto-detect (see `hyprctl monitors` to tune later)
          hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

          -- Cursor size
          hl.env("XCURSOR_SIZE", "24")
          hl.env("HYPRCURSOR_SIZE", "24")

          -- Look, feel, input, layout
          hl.config({
              general = {
                  gaps_in     = 1,
                  gaps_out    = 2,
                  border_size = 2,
                  layout      = "dwindle",
                  -- Cosy dark blue borders instead of Hyprland's default light
                  -- teal/green. Active window gets a soft midnight->dusk gradient;
                  -- unfocused windows fade to a dim navy.
                  col = {
                      active_border   = { colors = {"rgba(40E0D0ff)", "rgba(40E0D0aa)"}, angle = 45 },
                      inactive_border = { colors = {"rgba(000000ff)", "rgba(000000aa)"}, angle = 45 },
                  },
                  -- Let the mouse resize windows by dragging their edges/corners
                  -- (the usual desktop behaviour). extend_border_grab_area (default
                  -- 15px) makes the thin 2px border easy to grab.
                  resize_on_border      = true,
                  hover_icon_on_border  = true,
              },
              decoration = {
                  rounding = 8,
                  blur = { enabled = true },
              },
              animations = { enabled = true },
              dwindle = { preserve_split = true },
              misc = {
                  force_default_wallpaper = 0,
                  disable_hyprland_logo   = true,
              },
              input = {
                  kb_layout    = "no",   -- Norwegian, matches the rest of the system
                  follow_mouse = 1,
                  touchpad = { natural_scroll = true },
              },
          })

          -- Autostart. home-manager's systemd wiring for waybar/mako is unreliable
          -- (empty WantedBy), so launch them here directly like Hyprland's own
          -- example does. hypridle still starts fine via its systemd user service.
          hl.on("hyprland.start", function()
              -- Fallback wallpaper so the screen is never black, then waypaper
              -- picks a random one once its folder (on the ~/MEGA mount) is ready.
              hl.exec_cmd("${wallpaperStart}")
              hl.exec_cmd("waybar")
              hl.exec_cmd("mako")
              -- NetworkManager GUI agent. Its tray icon (shown in waybar's tray)
              -- lists all nearby networks and pops proper dialogs: full enterprise
              -- form for eduroam, captive-portal login prompts, hidden SSIDs, VPNs.
              hl.exec_cmd("nm-applet --indicator")
              hl.exec_cmd("wl-paste --type text --watch cliphist store")
              hl.exec_cmd("wl-paste --type image --watch cliphist store")
          end)

          -- Core keybindings
          hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
          hl.bind(mainMod .. " + space",  hl.dsp.exec_cmd(menu))
          hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
          hl.bind(mainMod .. " + T",      hl.dsp.window.float({ action = "toggle" }))
          hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen())
          hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
          hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd("hyprlock-random"))
          hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("cliphist list | rofi -dmenu -p clipboard | cliphist decode | wl-copy"))
          -- --copy-command: satty's built-in clipboard dies with the window (Wayland
          -- selections are served by the owning client). wl-copy forks and keeps
          -- serving the image after satty exits.
          hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty --filename - --copy-command 'wl-copy --type image/png'"))

          -- Focus movement (arrows + vim keys)
          hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
          hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
          hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
          hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
          hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
          hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
          hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
          hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

          -- Move / swap the focused window (SUPER + SHIFT + arrows)
          hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
          hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
          hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
          hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))

          -- Resize the focused window (SUPER + CTRL + arrows)
          hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
          hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x =  40, y = 0, relative = true }), { repeating = true })
          hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
          hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y =  40, relative = true }), { repeating = true })

          -- Quick app launches
          hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
          hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("dolphin"))
          hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("onenote"))

          -- Workspaces: SUPER+[1..0] switch, SUPER+SHIFT+[1..0] move window
          for i = 1, 10 do
              local key = i % 10
              hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
              hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
          end

          -- Mouse: drag to move / resize
          hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
          hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

          -- Mouse: scroll wheel to switch workspaces (SUPER + scroll)
          hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
          hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

          -- Media & brightness keys (work while locked)
          hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
          hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
          hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
          hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"),                          { locked = true, repeating = true })
          hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"),                          { locked = true, repeating = true })
          hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
          hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
          hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
        '';
      };

      # Stylix's hyprland target would inject color settings through the same buggy
      # settings->Lua path, so disable it; borders use Hyprland's defaults.
      stylix.targets.hyprland.enable = false;
    };
}
