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

    # Home Manager manages all your per-user dotfiles declaratively.
    # Tracks the 26.05 release and reuses the pinned nixpkgs above.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix applies one base16 color scheme + fonts across the whole system.
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        # Enable flakes + the new `nix` CLI permanently on the system.
        { nix.settings.experimental-features = [ "nix-command" "flakes" ]; }

        # System-wide theming.
        stylix.nixosModules.stylix

        # Home Manager as a NixOS module: your user config lives in ./home.
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # If HM would overwrite an existing dotfile, back it up instead of failing.
          home-manager.backupFileExtension = "hm-bak";
          home-manager.users.jakap42 = import ./home;
        }
      ];
    };
  };
}
