{ pkgs, ... }:
{
  # In 26.05 rofi is Wayland-capable by default (rofi-wayland was merged in).
  # Stylix themes it via its rofi target, so no manual theme is needed here.
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "${pkgs.kitty}/bin/kitty";
  };
}
