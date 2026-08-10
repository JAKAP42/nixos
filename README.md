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

## Setting up a new machine

Almost everything reproduces from this flake after `nixos-rebuild switch`. A few
things hold secrets or live only at runtime, so they are **not** in git and must
be set up by hand once per machine:

### Cloud storage (rclone) — required for the MEGA / OneDrive mounts

The `rclone-mega` and `rclone-onedrive` systemd services are defined in the
flake, but the credentials they use (OAuth tokens) live in
`~/.config/rclone/rclone.conf`, which is deliberately **not** committed (never
put plaintext tokens in git). On a fresh machine the mounts will fail until you
re-authenticate:

```sh
rclone config          # interactive: recreate the "onedrive" and "mega" remotes
systemctl --user restart rclone-onedrive rclone-mega
```

Keep the remote **names** exactly `onedrive` and `mega` so the services find them.
(If you'd rather have this fully automated, the alternative is a secrets manager
like sops-nix or agenix — more setup, but then even the tokens live in the flake.)

### KDE / Plasma desktop settings — not managed

Tweaks made in KDE's System Settings GUI (`kwinrc`, `kdeglobals`,
`kglobalshortcutsrc`, etc.) are stored under `~/.config` at runtime and are not
captured here. The Hyprland side *is* fully managed; the KDE fallback session is
configured by hand. Redo any KDE customizations manually on a new machine.

## Files

- `flake.nix` / `flake.lock` — entry point and pinned dependency versions
- `configuration.nix` — the actual system config
- `hardware-configuration.nix` — machine-specific (disks, filesystems); **committed on purpose** so this repo can rebuild the system
