# The actual machine. This is where the named nixosModules from the rest of the
# tree get assembled into a bootable system. Add or remove a line in `modules`
# to toggle a whole feature.
{ self, inputs, ... }:
let
  userconf = import ../../lib/user.nix;
in
{
  flake.nixosConfigurations.${userconf.host} = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    # Make `inputs` and `userconf` available to every module (incl. specialArgs
    # for imported files like hardware-configuration.nix).
    specialArgs = { inherit inputs userconf; };

    modules = with self.nixosModules; [
      # Results of the hardware scan. Kept at the repo root (outside ./modules)
      # because it's a plain NixOS module, not a flake-parts module.
      ../../hardware-configuration.nix

      # AMD display-engine debug workaround for this (AMD) laptop. Lived in
      # base.nix originally, but base is shared with the Intel/NVIDIA
      # 'home-machine' host where it does not belong, so it is pinned here.
      { boot.kernelParams = [ "amdgpu.dcdebugmask=0x40000" ]; }

      base
      user
      desktop
      sddm
      hyprland
      power
      stylix
      localsend
      kdeconnect
      gpu-screen-recorder
      protonvpn
    ];
  };
}
