{ pkgs, ... }:
let
  # Which web page to open. This lands on your OneNote notebooks after login.
  # School (Microsoft 365) accounts work here too — it redirects through the
  # normal Microsoft sign-in. Change the URL if you prefer a different entry.
  url = "https://www.onenote.com/notebooks";

  # Launch Chromium in "app mode": a single, chrome-less window that looks and
  # behaves like a native OneNote app instead of a browser tab. Firefox dropped
  # this feature, which is why we use Chromium just for this.
  #   --ozone-platform-hint=auto : run natively on Wayland (sharper, better scaling)
  #   --class=onenote            : stable window app_id, so Hyprland can target it
  onenote = pkgs.writeShellScriptBin "onenote" ''
    exec ${pkgs.chromium}/bin/chromium \
      --app=${url} \
      --ozone-platform-hint=auto \
      --class=onenote "$@"
  '';
in
{
  home.packages = [ pkgs.chromium onenote ];

  # Show up in the rofi launcher (SUPER + space) as a normal app.
  xdg.desktopEntries.onenote = {
    name = "OneNote";
    comment = "Microsoft OneNote (web app)";
    exec = "onenote";
    terminal = false;
    categories = [ "Office" ];
    startupNotify = true;
  };
}
