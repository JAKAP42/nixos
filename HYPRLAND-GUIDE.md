# Hyprland cheat-sheet & survival guide

Your desktop is **Hyprland**, a *tiling* window manager. Windows automatically
share the screen instead of floating on top of each other. Almost everything is
done with the keyboard. `SUPER` = the **Windows key**.

---

## The absolute essentials

| Keys | What it does |
|------|--------------|
| `SUPER` + `Enter` | Open a terminal (kitty) |
| `SUPER` + `Space` | **App launcher** — type an app name, press Enter to open it |
| `SUPER` + `Q` | Close the focused window |
| `SUPER` + `B` | Open Firefox |
| `SUPER` + `E` | Open the file manager (Dolphin) |

If you only remember one thing: **`SUPER`+`Space`** opens anything installed.

---

## Moving around

| Keys | What it does |
|------|--------------|
| `SUPER` + arrow keys (or `H` `J` `K` `L`) | Move focus between windows |
| `SUPER` + `Shift` + arrows | Move / swap the focused window |
| `SUPER` + `Ctrl` + arrows | Resize the focused window |
| `SUPER` + `F` | Fullscreen the focused window |
| `SUPER` + `T` | Toggle floating (window floats freely instead of tiling) |
| `SUPER` + hold mouse-left + drag | Move a window with the mouse |
| `SUPER` + hold mouse-right + drag | Resize a window with the mouse |

## Workspaces (virtual desktops)

| Keys | What it does |
|------|--------------|
| `SUPER` + `1`..`0` | Switch to workspace 1–10 |
| `SUPER` + `Shift` + `1`..`0` | Send the focused window to that workspace |
| `SUPER` + scroll wheel | Switch to the next / previous workspace |

Think of workspaces as extra screens: put your browser on 1, terminals on 2, etc.

## Handy tools

| Keys | What it does |
|------|--------------|
| `SUPER` + `V` | Clipboard history (pick something you copied earlier) |
| `SUPER` + `Shift` + `S` | Screenshot a region → opens in the satty editor |
| `SUPER` + `Escape` | Lock the screen |
| Volume / brightness / media keys | Work as expected (also while locked) |

## Session

| Keys | What it does |
|------|--------------|
| `SUPER` + `Shift` + `M` | Log out of Hyprland (back to the login screen) |

To **shut down / restart**: log out with `SUPER`+`Shift`+`M`, then use the power
buttons on the login screen. Or from a terminal: `systemctl poweroff` / `reboot`.

---

## If something breaks (your safety net)

- **Get a plain text console:** `Ctrl` + `Alt` + `F3` (log in with your username +
  password). Get back to the graphical session with `Ctrl` + `Alt` + `F1` (or `F2`).
- **Go back to the old KDE desktop:** log out, and at the login screen look for the
  session menu (bottom-left) to pick "Plasma". It's still installed as a fallback.

---

## Changing your setup (the NixOS way)

Your entire desktop is defined in `~/nixos/`. Nothing is configured by clicking —
you edit files and rebuild. Key files:

- `~/nixos/home/hyprland.nix` — keybinds, autostart, wallpaper, look & feel
- `~/nixos/home/waybar.nix` — the top bar
- `~/nixos/home/rofi.nix` — the app launcher
- `~/nixos/home/mako.nix` — notifications
- `~/nixos/stylix.nix` — colors & fonts (whole system)

After editing anything, apply it with:

```
sudo nixos-rebuild switch --flake ~/nixos#nixos
```

Config changes to Hyprland take effect on your **next login** (log out with
`SUPER`+`Shift`+`M` and back in). Changing the color scheme is one line in
`stylix.nix` (e.g. `gruvbox-dark-hard.yaml`, `nord.yaml`, `tokyo-night-dark.yaml`).

Everything is tracked in git under `~/nixos`, so you can always review or undo
changes, and old system versions are selectable at the boot menu.
