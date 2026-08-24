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

      # Make KDE apps find their application database in a Hyprland session.
      #
      # kbuildsycoca6 builds the *application* half of KDE's service cache
      # (ksycoca) by walking the XDG menu file "''${XDG_MENU_PREFIX}applications.menu".
      # The only menu file that exists here is plasma-applications.menu — a
      # Plasma session sets XDG_MENU_PREFIX=plasma- so it's found. Nothing sets
      # it under Hyprland, so kbuildsycoca6 looks for a plain applications.menu,
      # finds none, and indexes ZERO applications.
      #
      # The visible symptom is every KDE "Open With" / "Choose Application"
      # dialog coming up empty, for every file type — Dolphin can't open
      # anything. (Verified: without this, ksycoca held 0 desktop entries; with
      # it, 917.) Nothing to do with MIME defaults — xdg-open was fine all along.
      environment.sessionVariables.XDG_MENU_PREFIX = "plasma-";
    };
}
