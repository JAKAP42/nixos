{
  description = "NixOS configuration for host 'nixos' (dendritic, flake-parts)";

  inputs = {
    # Pinned to the exact nixpkgs revision this machine was already running,
    # so the first `nixos-rebuild switch --flake` is a no-op (no surprise upgrade).
    #
    # To upgrade later: change this to a branch and run `nix flake update`, e.g.
    #   nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";   # latest 26.05 stable
    # then review the flake.lock diff in git before rebuilding.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

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

    # torlink is a terminal torrent finder. Not in nixpkgs, so it comes from its
    # own flake. Upstream's package.nix lags the npm releases (it still pins
    # 1.4.1), so modules/home/torlink.nix overrides it up to the current tag --
    # see the comment there before touching either side.
    torlink = {
      url = "github:baairon/torlink";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko declares disk layout (partitions + filesystems) as data, so a
    # machine can be partitioned and formatted straight from this flake instead
    # of a hand-generated hardware-configuration.nix. Only hosts that import the
    # `disko` nixosModule are affected; the 'nixos' host does not, so it is
    # untouched. Referenced by modules/system/disko.nix.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-matlab provides the FHS dependency list (targetPkgs) that non-Nix
    # binaries like MATLAB need. Archived upstream but still evaluates fine.
    # MATLAB itself is installed manually into ~/matlab (multi-GB, not in Nix);
    # this only builds the sandbox that lets it run. See modules/home/matlab.nix.
    nix-matlab = {
      url = "gitlab:doronbehar/nix-matlab";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # The whole flake is assembled from the tree of modules under ./modules.
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree [ ./modules ]);
}
