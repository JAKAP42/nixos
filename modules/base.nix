# Core system settings that aren't tied to the desktop: boot, networking,
# locale, nix itself, and the handful of system-wide packages.
{
  flake.nixosModules.base =
    { pkgs, userconf, ... }:
    {
      # Enable flakes + the new `nix` CLI permanently on the system.
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      # Bootloader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 10;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = userconf.host;
      networking.networkmanager.enable = true;
      # Periodic connectivity probe so NetworkManager (and the nm-applet tray
      # agent) can detect captive portals — the "log in on a webpage" networks —
      # and prompt you to authenticate instead of silently sitting "connected".
      networking.networkmanager.settings.connectivity = {
        uri = "http://nmcheck.gnome.org/check_network_status.txt";
        interval = 300;
      };
      # NTNU's VPN (vpn.ntnu.no) speaks Cisco AnyConnect. openconnect is the
      # open-source client for that protocol; this plugin exposes it to
      # NetworkManager so the tunnel becomes an ordinary on/off entry in
      # nm-connection-editor and the waybar network menu, instead of a
      # terminal session you have to keep alive.
      #
      # Needed off-campus only: on eduroam at Gløshaugen you are already inside
      # NTNU's network. Elsewhere it is what gets you past the IP restriction on
      # sites like algdat.idi.ntnu.no.
      networking.networkmanager.plugins = with pkgs; [ networkmanager-openconnect ];

      time.timeZone = "Europe/Oslo";
      time.hardwareClockInLocalTime = true;

      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };

      # Generated but not used as anyone's locale. GTK takes the first day of
      # the week, and the week numbering that follows from it, out of LC_TIME.
      # Under en_US that is Sunday, which would put the clock calendar in
      # modules/home/waybar.nix one day out of step with the ISO week number
      # (%V) the bar prints directly above it -- the bar would say week 37 while
      # the calendar labelled the Sunday-started row containing the same day 37
      # as well, covering a different seven days. en_GB is the nearest locale
      # that starts weeks on Monday and numbers them the ISO way while leaving
      # month names in English, so the popup still reads like the bar. Only that
      # one window opts into it; everything else stays en_US.
      i18n.supportedLocales = [
        "C.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
        "en_GB.UTF-8/UTF-8"
      ];

      # Console keymap.
      console.keyMap = "no";

      # Allow unfree packages.
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        claude-code
        git

        # Archive tools: unzip (extract .zip), zip (create .zip),
        # p7zip (`7z`, handles many other formats both ways).
        unzip
        zip
        p7zip

        # The openconnect CLI, for setting up / debugging the NTNU VPN by hand
        # when the NetworkManager dialog is being unhelpful. See the plugin
        # comment up by networking.networkmanager for what this is for.
        openconnect

        # C/C++ toolchain: `gcc`, `g++`, `cc`, plus common build tools.
        gcc
        gnumake
        cmake
        pkg-config
      ];

      # This value determines the NixOS release from which the default settings
      # for stateful data were taken. Leave it at the first-install release.
      system.stateVersion = userconf.stateVersion;
    };
}
