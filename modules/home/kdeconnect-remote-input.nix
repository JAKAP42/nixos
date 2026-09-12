# KDE Connect remote input (phone as touchpad / presenter) under Hyprland.
#
# THE PROBLEM
#
# On Wayland, KDE Connect injects mouse and keyboard events through one channel
# only: the org.freedesktop.portal.RemoteDesktop portal (libei). Hyprland's
# portal backend does not implement that interface -- as of xdg-desktop-portal-
# hyprland v1.4.1 it declares Screenshot, ScreenCast, GlobalShortcuts and
# InputCapture, and nothing else. InputCapture looks like the answer but is the
# opposite direction: it grabs input happening *here* to forward elsewhere
# (input-leap), where we need remote events injected *into* this session.
# Upstream request is hyprwm/xdg-desktop-portal-hyprland#252, open since
# August 2024 with no PR. So touchpad, remote keyboard and presenter page-turning
# all fail with "RemoteDesktop portal not authenticated" and no other symptom.
#
# THE FIX
#
# hypr-kdeconnect-fix is a standalone portal backend that implements *only*
# org.freedesktop.impl.portal.RemoteDesktop and injects through
# zwlr_virtual_pointer_manager_v1 and zwp_virtual_keyboard_manager_v1, both of
# which Hyprland does support. Its .portal file declares that one interface, so
# it slots in beside xdg-desktop-portal-hyprland rather than replacing it:
# screenshots and screen sharing keep going through xdph exactly as before.
#
# It must be a *home* module, and that is not a style preference. NixOS patches
# xdg-desktop-portal to find backends via NIX_XDG_DESKTOP_PORTAL_DIR instead of
# XDG_DATA_DIRS, and in this session that variable resolves to
# /etc/profiles/per-user/<user>/share/xdg-desktop-portal/portals -- the
# home-manager profile. A backend added through the system-level
# xdg.portal.extraPortals lands in /run/current-system/sw/share instead and is
# invisible to the running portal frontend. home.packages puts the .portal file
# exactly where the frontend actually looks. (That same override is why only
# hyprland.portal is ever visible here; it also means the gtk and kde backends
# listed in xdg.portal.extraPortals are dead weight in this session, which is a
# separate pre-existing issue and not something this module tries to fix.)
#
# WHAT YOU ARE TRUSTING
#
# Two things worth re-reading before blaming this module for something odd:
#
#   1. Upstream's README carries the author's own warning that the code is
#      "99% vibe coded with OpenAI CodeX", manually audited afterwards. It is
#      not sloppy -- MIT, unit tests, a security_policy header, and PIE/RELRO/
#      stack-protector hardening that its own ctest suite verifies -- but nobody
#      here has read the C++.
#   2. It deliberately does not implement a permission dialog. Once this is
#      running, anything that can reach the portal can synthesise keystrokes and
#      clicks into the session without a prompt. The only gate is KDE Connect's
#      pairing list. It runs as this user, so this is not privilege escalation,
#      just an input-injection surface that did not exist before.
#
# Removing it is one line in modules/user.nix plus a rebuild; the portal file
# leaves the profile and KDE Connect goes back to failing the same way.
#
# Touchscreen events and InputCapture edge-capture are not implemented upstream.
# KDE Connect 26.04+ prefers libei's ConnectToEIS over the older Notify* methods,
# which this backend handles -- worth knowing because the other bridge projects
# predate that and will not work against kdeconnect 26.04.
{
  flake.homeModules.kdeconnectRemoteInput =
    { pkgs, ... }:
    let
      hypr-kdeconnect-portal = pkgs.stdenv.mkDerivation {
        pname = "hypr-kdeconnect-fix";
        version = "0-unstable-2026-09-07";

        src = pkgs.fetchFromGitHub {
          owner = "gfhdhytghd";
          repo = "hypr-kdeconnect-fix";
          rev = "0bc47e676ae2d6964cec4020be9966bbe85985e6";
          hash = "sha256-s8hWpEIyWpwW9w8t80Byqp+8jG0ChddtbDB7eJ/7ebA=";
        };

        nativeBuildInputs = with pkgs; [
          cmake
          pkg-config
          wayland-scanner # generates the virtual-pointer/virtual-keyboard glue
        ];

        # libei carries libeis-1.0.pc -- the *server* half of libei, which is
        # what a portal backend needs (KDE Connect is the ei client here).
        buildInputs = with pkgs; [
          qt6.qtbase
          wayland
          libxkbcommon
          libei
        ];

        # Qt6 Core + DBus only, no GUI, so there are no plugin or QML paths to
        # inject: skip the Qt wrapper and keep $out/bin/hypr-kdeconnect-portal a
        # real ELF instead of a shell wrapper. qtbase's setup hook refuses to
        # build unless this choice is stated explicitly one way or the other.
        dontWrapQtApps = true;

        # Upstream's ctest suite covers the keysym resolver, the security policy,
        # the generated portal metadata, and (via readelf) that hardening
        # actually survived the build.
        doCheck = true;

        meta = {
          description = "RemoteDesktop portal backend enabling KDE Connect remote input on Hyprland";
          homepage = "https://github.com/gfhdhytghd/hypr-kdeconnect-fix";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.linux;
          mainProgram = "hypr-kdeconnect-portal";
        };
      };
    in
    {
      # Puts hypr-kdeconnect.portal into the home-manager profile's
      # share/xdg-desktop-portal/portals -- see the NIX_XDG_DESKTOP_PORTAL_DIR
      # note above for why that location is the whole point.
      home.packages = [ hypr-kdeconnect-portal ];

      # The shipped D-Bus activation file says SystemdService=, so dbus-broker
      # hands activation to systemd and the unit has to exist or the portal
      # frontend gets an activation error instead of a backend. The package
      # installs its own copy under share/systemd/user, but systemd --user does
      # not scan Nix profile share dirs, so it is redeclared here: that also
      # means home-manager does the daemon-reload on switch.
      #
      # Directives mirror upstream's data/hypr-kdeconnect-portal.service.in --
      # diff against that file when bumping the rev. No [Install] section on
      # purpose: it is dbus-activated on demand, not started at login.
      systemd.user.services.hypr-kdeconnect-portal = {
        Unit = {
          Description = "KDE Connect RemoteDesktop portal backend (virtual-input Wayland compositors)";
          PartOf = "xdg-desktop-portal.service";
        };
        Service = {
          Type = "dbus";
          BusName = "org.freedesktop.impl.portal.desktop.hypr_kdeconnect";
          ExecStart = "${hypr-kdeconnect-portal}/bin/hypr-kdeconnect-portal";
          Restart = "on-failure";
          RestartSec = "1s";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          RestrictSUIDSGID = true;
          RestrictAddressFamilies = "AF_UNIX";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
        };
      };

      # No portals.conf on purpose. Nothing else in this session declares
      # RemoteDesktop, and this backend's UseIn list already covers Hyprland, so
      # the frontend routes it here unambiguously. Adding a portals.conf with a
      # `default=` line would be the risky move: it would start overriding the
      # routing of Screenshot/ScreenCast too, and the gtk/kde backends it would
      # name are not visible in this profile.
    };
}
