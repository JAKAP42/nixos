# Standalone GUI applications: things that are installed and then just run,
# with no Nix-side configuration of their own.
#
# If an app ever grows real config (a settings file, a theme, a keybind that
# other modules call), give it its own module and move it out of here --
# otherwise this file slowly turns back into the catch-all bucket it replaced.
{
  flake.homeModules.apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        gimp        # image editing (photos, memes, adding text)
        libresprite # pixel art / sprite editor for game art
        switcheroo  # convert/resize images between formats (png, webp, avif, jxl...)
      ];
    };
}
