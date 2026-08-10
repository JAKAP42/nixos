# System-side Hyprland enablement. This makes the Hyprland session selectable
# at SDDM (alongside Plasma) and wires up the required Wayland portals. The
# actual window-manager config lives in the home module (modules/home/hyprland.nix).
{
  flake.nixosModules.hyprland =
    { ... }:
    {
      # Enables the Hyprland session plus the required Wayland portals. Plasma
      # stays installed as a fallback: if Hyprland ever misbehaves, just pick
      # "Plasma" at login.
      programs.hyprland.enable = true;
      # Sets up the PAM entry so hyprlock can actually unlock the session.
      programs.hyprlock.enable = true;
    };
}
