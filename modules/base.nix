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
      boot.kernelParams = [ "amdgpu.dcdebugmask=0x40000" ];

      networking.hostName = userconf.host;
      networking.networkmanager.enable = true;

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

      # Console keymap.
      console.keyMap = "no";

      # Allow unfree packages.
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        claude-code
        git

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
