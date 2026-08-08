{ pkgs, lib, ... }:
let
  # Gather every KDE wallpaper (they're nested as <Name>/contents/images/<res>)
  # plus the Hyprland ones into one flat folder of image files that waypaper
  # can show as a grid.
  wallpapers = pkgs.runCommand "wallpaper-collection" { } ''
    mkdir -p $out
    shopt -s nullglob
    for d in ${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/*/; do
      name=$(basename "$d")
      img=""
      for f in "$d"contents/images/*.png "$d"contents/images/*.jpg; do img="$f"; done
      if [ -n "$img" ]; then
        ln -s "$img" "$out/$name.''${img##*.}"
      fi
    done
    ln -s ${pkgs.hyprland}/share/hypr/wall0.png "$out/Hyprland-1.png"
    ln -s ${pkgs.hyprland}/share/hypr/wall1.png "$out/Hyprland-2.png"
    ln -s ${pkgs.hyprland}/share/hypr/wall2.png "$out/Hyprland-3.png"
  '';
in
{
  # Browsable wallpaper folder for waypaper. It's a read-only link to the
  # curated set above; to use your own images, save them anywhere and point
  # waypaper's folder chooser at that location instead.
  home.file."Pictures/wallpapers".source = wallpapers;

  # Seed a WRITABLE waypaper config once (a home-manager symlink would be
  # read-only, so waypaper couldn't save your picks). Only created if absent.
  home.activation.waypaperSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.config/waypaper/config.ini"
    if [ ! -e "$cfg" ]; then
      mkdir -p "$HOME/.config/waypaper"
      {
        echo "[Settings]"
        echo "folder = $HOME/Pictures/wallpapers"
        echo "backend = swaybg"
        echo "fill = fill"
        echo "monitors = All"
      } > "$cfg"
    fi
  '';
}
