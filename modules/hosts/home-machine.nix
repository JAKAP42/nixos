# The 'home-machine' desktop: Intel CPU, NVIDIA GeForce GTX 1050, NixOS on the
# nvme SSD (disko-managed), /home on the 931 GB HDD. Sibling of the 'nixos'
# laptop host; the two share every module except the hardware- and GPU-specific
# bits below (and the laptop-only `power` battery policy, which is omitted here).
{ self, inputs, ... }:
let
  # Reuse the shared identity (username, displayname, stateVersion) but override
  # the per-machine facts. `disk` is consumed by modules/system/disko.nix.
  userconf = (import ../../lib/user.nix) // {
    host = "home-machine";
    disk = "nvme0n1";
  };
in
{
  flake.nixosConfigurations.${userconf.host} = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = { inherit inputs userconf; };

    modules = with self.nixosModules; [
      base
      user
      desktop
      sddm
      hyprland
      stylix
      localsend
      kdeconnect
      gpu-screen-recorder
      protonvpn

      # This machine's declarative disk layout + NVIDIA driver.
      disko
      nvidia

      # Hardware specifics for this box, in lieu of a generated
      # hardware-configuration.nix. Filesystems for / and /boot come from disko;
      # swap comes from disko; only /home is declared here (separate disk).
      (
        { config, lib, modulesPath, ... }:
        {
          imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

          boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "uas" "sd_mod" ];
          boot.initrd.kernelModules = [ ];
          boot.kernelModules = [ "kvm-intel" ];
          boot.extraModulePackages = [ ];

          nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
          hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

          # /home is the 931 GB HDD (ext4, label "home"). Mounted by label so no
          # UUID leaks into the repo and it stays portable. disko never touches
          # this disk.
          fileSystems."/home" = {
            device = "/dev/disk/by-label/home";
            fsType = "ext4";
          };

          # The existing /home/jakap42 directory on that HDD is owned by uid
          # 1001; pin the user to it so the account owns its home after install.
          users.users.${userconf.username}.uid = 1001;
        }
      )
    ];
  };
}
