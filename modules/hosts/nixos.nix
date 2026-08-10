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

      base
      user
      desktop
      hyprland
      stylix
    ];
  };
}
