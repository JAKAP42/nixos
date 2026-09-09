# ONLYOFFICE Desktop Editors: the office suite used for Microsoft-format
# documents (.docx / .xlsx / .pptx are its *native* formats, so round-tripping
# files with people on real Office keeps the formatting).
#
# File associations live in mime.nix; this module owns the app's own settings.
#
# Two things need fixing on this machine, both caused by the same thing: the
# app is Qt + an embedded Chromium (CEF), the nixpkgs wrapper hard-codes
# QT_QPA_PLATFORM=xcb, and that cannot be overridden from outside. So it always
# runs under XWayland, and on a fractionally-scaled monitor (eDP-1 is 1920x1080
# at scale 1.5) XWayland renders at the *logical* 1280x720 and lets the
# compositor upscale -- which is the blurry "low resolution" look.
#
# The fix is a pair, and both halves are required:
#   1. hyprland.nix sets xwayland.force_zero_scaling, so XWayland apps render
#      at real pixel density instead of being upscaled.
#   2. `uiscaling` below scales the UI back up to the right size.
# Note it must be `uiscaling` and not QT_SCALE_FACTOR: the entire UI is drawn
# by CEF, which ignores the Qt variable, so setting that scales the Qt window
# frame but not its contents and leaves the layout visibly broken.
{
  flake.homeModules.onlyoffice =
    { pkgs, lib, ... }:
    let
      # Keep in step with the monitor scale in `hyprctl monitors` (1.5 today).
      # Too low and the UI is tiny; too high and it overflows the window.
      uiScaling = "1.5";

      # theme-night is the darkest of the three dark themes the binary ships;
      # the others are theme-dark (mid grey) and theme-contrast-dark.
      uiTheme = "theme-night";

      # ONLYOFFICE writes its own runtime state (window position, and every
      # setting toggled in the GUI) back into this same file, so Home Manager
      # can't own it outright the way it owns mimeapps.list -- a read-only
      # symlink into the store would silently break saving *all* of those.
      # Instead, rewrite just our two keys on activation and leave the rest of
      # the file alone. Trade-off: changing the theme in the app's own Settings
      # page sticks until the next rebuild, which then resets it to the value
      # above. Change it here, not there.
      settings = {
        UITheme = uiTheme;
        uiscaling = uiScaling;
      };

      setKey = key: value: ''
        if ${pkgs.gnugrep}/bin/grep -q '^${key}=' "$conf"; then
          ${pkgs.gnused}/bin/sed -i 's|^${key}=.*|${key}=${value}|' "$conf"
        else
          ${pkgs.gnused}/bin/sed -i '/^\[General\]/a ${key}=${value}' "$conf"
        fi
      '';
    in
    {
      home.packages = [ pkgs.onlyoffice-desktopeditors ];

      home.activation.onlyofficeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        conf="$HOME/.config/onlyoffice/DesktopEditors.conf"
        $DRY_RUN_CMD mkdir -p "$(dirname "$conf")"

        # A fresh install has no file at all, and the [General] header has to
        # exist before the `sed` inserts below have an anchor to append after.
        if [ ! -f "$conf" ]; then
          $DRY_RUN_CMD printf '[General]\n' > "$conf"
        elif ! ${pkgs.gnugrep}/bin/grep -q '^\[General\]' "$conf"; then
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i '1i [General]' "$conf"
        fi

        ${lib.concatStrings (lib.mapAttrsToList setKey settings)}
      '';
    };
}
