{
  flake.homeModules.rofi =
    { pkgs, ... }:
    {
      # Supplies the "Papirus-Dark" icon set named in extraConfig below; without
      # it rofi's drun mode falls back to blank/generic icons.
      home.packages = [ pkgs.papirus-icon-theme ];

      # In 26.05 rofi is Wayland-capable by default (rofi-wayland was merged in).
      # Stylix themes it via its rofi target, so no manual theme is needed here.
      programs.rofi = {
        enable = true;
        package = pkgs.rofi;
        terminal = "${pkgs.kitty}/bin/kitty";

        # Show each app's real icon next to its name in `rofi -show drun`.
        # Stylix still owns the colors/theme; these are behaviour settings only.
        extraConfig = {
          show-icons = true;
          icon-theme = "Papirus-Dark";
          drun-display-format = "{name}";
        };
      };
    };
}
