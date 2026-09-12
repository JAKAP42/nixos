# The graphical desktop: KDE Plasma (fallback) + SDDM login, keyboard layout,
# audio, printing, and Firefox. Hyprland itself lives in ./hyprland.nix.
{
  flake.nixosModules.desktop =
    { pkgs, ... }:
    {
      # Enable the X11 windowing system (also backs the SDDM greeter).
      services.xserver.enable = true;

      # Enable the KDE Plasma Desktop Environment. The greeter's looks (theme +
      # random wallpaper) live in ./sddm.nix.
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

      # Bluetooth. `hardware.bluetooth` is just the BlueZ daemon -- it gives you
      # `bluetoothctl` on the command line and nothing else; the GUI half is
      # blueman below.
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        # Battery reporting for headsets/controllers (the BlueZ Battery1
        # interface, which waybar's bluetooth pill reads) is still gated behind
        # BlueZ's experimental flag. Drop this line if a device misbehaves.
        settings.General.Experimental = true;
      };

      # The Bluetooth counterpart to nm-applet: `blueman-applet` (tray icon,
      # execed from modules/home/hyprland.nix) and `blueman-manager` (the full
      # pair/connect window, opened by waybar's bluetooth pill). This module also
      # installs the polkit rules that let pairing happen without root, so
      # installing the package by hand is NOT enough -- keep it as a service.
      services.blueman.enable = true;

      # Secret Service (org.freedesktop.secrets) for the Hyprland session.
      #
      # Anything storing a password or key through libsecret -- browsers, many
      # GNOME and Electron apps, CLI tools that cache tokens -- talks to that
      # bus name. Plasma provides it via KWallet's `ksecretd` bridge, but the
      # shipped D-Bus service file registers only `org.kde.secretservicecompat`,
      # and nothing claims the freedesktop name unless a full Plasma session
      # autostarts it. Under Hyprland nothing does, so libsecret clients fail
      # with "the desktop keyring is unavailable".
      #
      # Registering ksecretd under the freedesktop name makes it *activatable*:
      # the first client to ask starts it, and it costs nothing until then.
      # Deliberately not a Hyprland exec-once or a systemd user unit, either of
      # which would race against user services wanting a keyring at login.
      services.dbus.packages = [
        (pkgs.writeTextFile {
          name = "ksecretd-freedesktop-secrets-activation";
          destination = "/share/dbus-1/services/org.freedesktop.secrets.service";
          text = ''
            [D-BUS Service]
            Name=org.freedesktop.secrets
            Exec=${pkgs.kdePackages.kwallet}/bin/ksecretd
          '';
        })
      ];

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
