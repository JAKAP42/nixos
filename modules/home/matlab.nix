# MATLAB R2026a launcher for NixOS.
#
# MATLAB is proprietary and installed manually into ~/matlab (via the graphical
# installer, using the NTNU login-named-user license). That multi-GB tree is NOT
# managed by Nix. What *is* managed here is the FHS sandbox that lets the non-Nix
# MATLAB binaries find their shared libraries, plus the rofi launcher entries.
{ inputs, ... }:
{
  flake.homeModules.matlab =
    { pkgs, ... }:
    let
      # nix-matlab's dependency list + libraries newer MATLAB needs directly
      # that the archived list omits (freetype was the one that broke the GUI).
      targetPkgs = ps: (inputs.nix-matlab.targetPkgs ps) ++ (with ps; [
        freetype       # libfreetype.so.6  (needed by the R2026a GUI directly)
        fribidi        # libfribidi.so.0
        pixman         # libpixman-1.so.0
        libtirpc       # libtirpc.so.3
        xorg.libXau            # libXau.so.6
        xorg.libXdmcp          # libXdmcp.so.6
        xorg.libXfont2         # libXfont2.so.2
        xorg.xcbutil           # libxcb-util.so.1
        xorg.xcbutilcursor     # libxcb-cursor.so.0
        xorg.xcbutilwm         # libxcb-icccm.so.4
        xorg.xcbutilimage      # libxcb-image.so.0
        xorg.xcbutilkeysyms    # libxcb-keysyms.so.1
        xorg.xcbutilrenderutil # libxcb-render-util.so.0
      ]);

      # `matlab` on PATH: enters the FHS sandbox and runs the installed binary.
      # INSTALL_DIR is fixed at ~/matlab (where the installer put it).
      matlab = pkgs.buildFHSEnv {
        name = "matlab";
        inherit targetPkgs;
        runScript = pkgs.writeShellScript "matlab-runner" ''
          # Force Qt onto XWayland rather than probing Wayland directly.
          export QT_QPA_PLATFORM=xcb
          # Apps launched from rofi/Hyprland don't always inherit DISPLAY, so the
          # GUI silently fails to open. Default it to the XWayland socket (:0).
          export DISPLAY=''${DISPLAY:-:0}
          exec env LD_PRELOAD=/lib/libstdc++.so "$HOME/matlab/bin/matlab" "$@"
        '';
      };

      # `matlab-install-shell`: an interactive shell inside the SAME FHS sandbox,
      # used once per machine to run the graphical MATLAB installer (./install).
      # See ~/nixos/docs/matlab.md for the full procedure.
      matlab-install-shell = pkgs.buildFHSEnv {
        name = "matlab-install-shell";
        inherit targetPkgs;
        runScript = pkgs.writeShellScript "matlab-install-shell-runner" ''
          export QT_QPA_PLATFORM=xcb
          export DISPLAY=''${DISPLAY:-:0}
          exec bash "$@"
        '';
      };
    in
    {
      home.packages = [ matlab matlab-install-shell ];

      # Show up in the rofi launcher (SUPER + space) as normal apps.
      # `-desktop` is required when launching from a menu/icon: without a
      # controlling terminal, MATLAB otherwise starts in console mode, hits EOF
      # on stdin and exits immediately (so the GUI never appears). From a
      # terminal, plain `matlab` still works — this flag only matters for rofi.
      xdg.desktopEntries.matlab = {
        name = "MATLAB";
        comment = "MATLAB R2026a (NixOS FHS sandbox)";
        exec = "matlab -desktop";
        terminal = false;
        categories = [ "Development" "Science" "Math" ];
      };

      # Simulink is just MATLAB started straight into the Simulink environment.
      xdg.desktopEntries.simulink = {
        name = "Simulink";
        comment = "Simulink (opens via MATLAB, NixOS FHS sandbox)";
        exec = "matlab -desktop -r simulink";
        terminal = false;
        categories = [ "Development" "Science" "Math" ];
      };
    };
}
