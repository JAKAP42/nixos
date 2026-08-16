{
  flake.homeModules.packages =
    { pkgs, ... }:
    {
      # Command-line tools the Hyprland keybinds and helpers rely on.
      home.packages = with pkgs; [
        swaybg         # sets the desktop wallpaper
        waypaper       # GUI wallpaper picker (browse + click to set)
        wl-clipboard   # wl-copy / wl-paste, used by cliphist
        cliphist       # clipboard history store + picker backend
        grim           # screenshot capture
        slurp          # region selection for screenshots
        satty          # screenshot annotation editor
        brightnessctl  # screen brightness keys
        playerctl      # media play/pause/next keys
        pavucontrol    # graphical audio mixer
        networkmanagerapplet  # nm-applet tray agent + nm-connection-editor GUI
        papirus-icon-theme  # app icons shown in the rofi launcher
        nwg-drawer     # full-screen grid app drawer with large icons
        xournalpp      # PDF annotation / handwriting notes editor

        # Python 3 interpreter. Add liberaries in brackets!
        (python3.withPackages (ps: with ps; [ numpy requests matplotlib ]))
      ];
    };
}
