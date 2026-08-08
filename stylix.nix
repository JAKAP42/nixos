{ pkgs, config, ... }:
{
  # One base16 palette + font set flows into Hyprland, waybar, rofi, kitty,
  # mako, hyprlock, GTK/Qt apps, and more.
  stylix = {
    enable = true;
    polarity = "dark";

    # Pick any scheme from the base16-schemes package. To change the whole
    # system's colors, swap the filename below and rebuild. A few options:
    #   catppuccin-mocha.yaml  gruvbox-dark-hard.yaml  tokyo-night-dark.yaml
    #   nord.yaml  rose-pine.yaml  everforest.yaml
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # No wallpaper file needed: this generates a solid 1x1 image in base00.
    # Point this at a real image path later if you want an actual wallpaper.
    image = config.lib.stylix.pixel "base00";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        terminal = 12;
        desktop = 11;
        popups = 11;
      };
    };
  };
}
