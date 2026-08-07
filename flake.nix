{
  description = "NixOS configuration for host 'nixos'";

  inputs = {
    # Pinned to the exact nixpkgs revision this machine was already running,
    # so the first `nixos-rebuild switch --flake` is a no-op (no surprise upgrade).
    #
    # To upgrade later: change this to a branch and run `nix flake update`, e.g.
    #   nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";   # latest 26.05 stable
    # then review the flake.lock diff in git before rebuilding.
    nixpkgs.url = "github:NixOS/nixpkgs/445d861c6d31b4af0c79d8d4be2331f762a361d7";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        # Enable flakes + the new `nix` CLI permanently on the system.
        { nix.settings.experimental-features = [ "nix-command" "flakes" ]; }
      ];
    };
  };
}
