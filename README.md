# NixOS configuration

Flake-based NixOS config for host `nixos`.

## Apply changes

```sh
sudo nixos-rebuild switch --flake ~/nixos#nixos
```

(`nixos` after the `#` is the hostname / the `nixosConfigurations.<name>` key in `flake.nix`.)

## Upgrade nixpkgs

Point `nixpkgs.url` in `flake.nix` at a branch (e.g. `github:NixOS/nixpkgs/nixos-26.05`), then:

```sh
nix flake update        # updates flake.lock
git diff flake.lock     # review what changed
sudo nixos-rebuild switch --flake ~/nixos#nixos
```

Roll back a bad upgrade with `git checkout flake.lock` (or pick an older generation in the boot menu).

## Files

- `flake.nix` / `flake.lock` — entry point and pinned dependency versions
- `configuration.nix` — the actual system config
- `hardware-configuration.nix` — machine-specific (disks, filesystems); **committed on purpose** so this repo can rebuild the system
