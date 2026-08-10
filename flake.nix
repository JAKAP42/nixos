{
  description = "NixOS configuration for host 'nixos' (dendritic, flake-parts)";

  inputs = {
    # Pinned to the exact nixpkgs revision this machine was already running,
    # so the first `nixos-rebuild switch --flake` is a no-op (no surprise upgrade).
    #
    # To upgrade later: change this to a branch and run `nix flake update`, e.g.
    #   nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";   # latest 26.05 stable
    # then review the flake.lock diff in git before rebuilding.
    nixpkgs.url = "github:NixOS/nixpkgs/445d861c6d31b4af0c79d8d4be2331f762a361d7";

    # flake-parts lets us split the flake into many small "flake modules"
    # instead of one big outputs function.
    flake-parts.url = "github:hercules-ci/flake-parts";

    # import-tree auto-discovers and imports every *.nix file under ./modules,
    # so there are no manual `imports = [ ... ]` lists to maintain (the
    # "dendritic" pattern).
    import-tree.url = "github:vic/import-tree";

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

  # The whole flake is assembled from the tree of modules under ./modules.
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree [ ./modules ]);
}
