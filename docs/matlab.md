# Installing MATLAB (+ Simulink) on NixOS

How this machine runs MATLAB, and how to reproduce it on a new PC.
License: NTNU (login-named-user) — https://i.ntnu.no/wiki/-/wiki/Norsk/Matlab

## The idea

MATLAB is proprietary and **cannot** be a Nix package. So we split it in two:

1. **The MATLAB program itself** — installed manually with MathWorks' graphical
   installer into `~/matlab`. This multi-GB tree is *not* tracked by Nix and does
   not live in the flake. It just sits in your home directory.
2. **Everything around it** — tracked in the flake at
   `~/nixos/modules/home/matlab.nix`:
   - an **FHS sandbox** so the non-Nix MATLAB binaries can find their shared
     libraries (`/usr/lib`, `libfreetype.so.6`, the xcb libs, etc.),
   - the `matlab` and `matlab-install-shell` commands on your `PATH`,
   - the **MATLAB** and **Simulink** rofi launcher entries.

The flake input `nix-matlab` (in `~/nixos/flake.nix`) provides the base list of
FHS dependencies; `matlab.nix` adds a few libraries the archived list misses
(notably `freetype`).

## Setting it up on a NEW PC

Assumes your `~/nixos` flake is already applied on the new machine (it includes
the `matlab` module, so `matlab` and `matlab-install-shell` are already on PATH).

### 1. Download the installer

- Log in to the NTNU MATLAB portal and download the **Linux** installer
  (`matlab_R20XXx_Linux.zip`).
- Unzip it (the flake already installs `unzip`):

  ```
  cd ~/Downloads
  unzip matlab_R20XXx_Linux.zip -d matlab-installer
  ```

### 2. Run the installer inside the FHS sandbox

The raw `./install` binary will NOT work directly on NixOS — it needs the
sandbox. Enter it:

```
matlab-install-shell
```

Then, inside that shell:

```
cd ~/Downloads/matlab-installer
./install
```

The graphical installer opens (may take 10-20 s). In the wizard:

- **Sign in** with your MathWorks/NTNU account (this is a login-named-user
  license — there is no activation key and no "Activate" tab; you log in when
  MATLAB starts).
- **Accept** the license.
- **Installation folder:** set it to exactly **`/home/<user>/matlab`**
  (i.e. `~/matlab`). This matters — the launcher expects MATLAB at `~/matlab`.
  (On the first attempt here it was accidentally installed straight into
  `~/Desktop`; if that happens, just move the MATLAB tree into `~/matlab`.)
- **Products:** tick **MATLAB**, **Simulink**, and any toolboxes you want.
- Let it download/install (several GB).

Type `exit` to leave the sandbox shell when done.

### 3. Launch it

- From **rofi** (`SUPER + Space`): type **MATLAB** or **Simulink**.
  First launch takes ~15-20 s and opens on the currently active workspace.
- From a **terminal**: just run `matlab`.

That's it — no further config. The launcher points at `~/matlab` automatically.

## Gotchas we hit (so you don't debug them again)

- **Installer did nothing / exit 42:** missing system libraries in the sandbox,
  primarily `libfreetype.so.6`. Fixed by the extra libs in `targetPkgs` in
  `matlab.nix`. If a *future* MATLAB release fails to launch with a
  `error while loading shared libraries: libX.so` message, add that library's
  nixpkgs package to that `targetPkgs` list and rebuild.
- **Rofi launcher did nothing (but terminal worked):** launched from a menu/icon
  MATLAB has no controlling terminal, so it started in console mode and exited
  immediately. Fix = the **`-desktop`** flag in the `.desktop` entries. Keep it.
- **GUI didn't appear under Hyprland:** MATLAB's GUI uses Qt/xcb (XWayland), so
  the launcher forces `QT_QPA_PLATFORM=xcb` and defaults `DISPLAY=:0`.

## Files involved

- `~/nixos/flake.nix` — adds the `nix-matlab` input.
- `~/nixos/modules/home/matlab.nix` — sandbox, commands, launchers.
- `~/nixos/modules/user.nix` — imports the `matlab` home module.
- `~/nixos/docs/matlab.md` — this document.
- `~/matlab/` — the actual install (NOT tracked; recreate via the steps above).

## Removing MATLAB

```
rm -rf ~/matlab ~/.MathWorks
```

Then drop the `matlab` import from `user.nix` (and optionally the `nix-matlab`
input from `flake.nix`) and rebuild.
