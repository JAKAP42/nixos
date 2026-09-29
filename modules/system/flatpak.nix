# Flatpak, for the handful of apps that only ship as one. Right now that means
# Sober: Roblox on Linux.
#
# Roblox has no Linux client, and the Wine route (Vinegar, Grapejuice) died when
# the Hyperion/Byfron anti-cheat started rejecting Wine — those projects now
# only cover Roblox Studio. Sober runs Roblox's *Android* build in a
# compatibility layer instead, which the anti-cheat accepts. It is not in
# nixpkgs and upstream ships Flatpak only, so this is the supported path.
#
# The remote and the apps are imperative state, not config — one-time setup
# after the first rebuild:
#   flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
#   flatpak install flathub org.vinegarhq.Sober
# Updates come from `flatpak update`, not from nixos-rebuild. That is the price
# of using Flatpak at all; keep it to apps that genuinely have no Nix package.
#
# Wayland portals (file picker, screenshare) come from programs.hyprland.enable
# in modules/system/hyprland.nix, so nothing extra is needed for them here.
#
# Removing this module reverts the system side, but leaves the downloaded
# runtimes and app data behind in /var/lib/flatpak and ~/.var/app — delete those
# by hand if you want the disk space back.
{
  flake.nixosModules.flatpak =
    { ... }:
    {
      services.flatpak.enable = true;
    };
}
