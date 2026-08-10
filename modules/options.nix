# flake-parts' core declares `flake.nixosModules` and `flake.nixosConfigurations`
# for us, but NOT `flake.homeModules`. Declare it here so home-manager modules
# spread across the tree can register themselves under it.
{ lib, ... }:
{
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Reusable home-manager modules, keyed by name.";
  };

  # flake-parts wants to know which systems to build for. We only have one host.
  config.systems = [ "x86_64-linux" ];
}
