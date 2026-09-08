# The graphical desktop: KDE Plasma (fallback) + SDDM login, keyboard layout,
# audio, printing, and Firefox. Hyprland itself lives in ./hyprland.nix.
{
  flake.nixosModules.desktop =
    { ... }:
    {
      # Enable the X11 windowing system (also backs the SDDM greeter).
      services.xserver.enable = true;

      # Enable the KDE Plasma Desktop Environment.
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;

      # Log straight into Hyprland by default (no need to hunt for the session
      # picker). To go back to the old desktop, change this to "plasma" (or
      # "plasmawayland") and rebuild.
      services.displayManager.defaultSession = "hyprland";

      # Configure keymap in X11.
      services.xserver.xkb = {
        layout = "no";
        variant = "";
      };

      # Enable CUPS to print documents.
      services.printing.enable = true;

      # Enable sound with pipewire.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      # Install firefox.
      programs.firefox = {
        enable = true;

        # uBlock Origin, installed declaratively via Firefox's enterprise policy
        # system. Firefox on Chromium-based Manifest V3 is why we bother: Chrome
        # only allows the crippled "uBO Lite", while Firefox still runs the full
        # extension.
        #
        # installation_mode is "normal_installed" rather than "force_installed"
        # on purpose -- force_installed would pin the extension so it cannot be
        # disabled, which breaks the ability to switch it off for a single site.
        policies.ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "normal_installed";
          };
        };
      };
    };
}
