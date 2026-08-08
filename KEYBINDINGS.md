# Hyprland keybindings

`SUPER` = the **Windows key**. Config lives in `~/nixos/home/hyprland.nix`.

| Keys | Action |
|------|--------|
| Super + Return | Terminal (kitty) |
| Super + Space | App launcher (rofi) |
| Super + Q | Close window |
| Super + F | Fullscreen toggle |
| Super + T | Toggle floating |
| Super + B / E | Firefox / Dolphin |
| Super + arrows *or* H/J/K/L | Move focus |
| Super + Shift + arrows | Move window |
| Super + Ctrl + arrows | Resize window |
| Super + 1–0 | Switch workspace |
| Super + Shift + 1–0 | Send window to workspace |
| Super + scroll | Switch workspace |
| Super + drag / right-drag | Move / resize with mouse |
| Super + V | Clipboard history |
| Super + Shift + S | Screenshot |
| Super + Escape | Lock screen |
| Super + Shift + M | Exit Hyprland |
| Volume / brightness / media keys | Work as expected (also while locked) |

Note: `J`/`K` are the vim-style focus keys (J = down, K = up).

After editing `hyprland.nix`, apply with:

```
sudo nixos-rebuild switch --flake ~/nixos#nixos
```
