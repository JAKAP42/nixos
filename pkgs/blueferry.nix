# BlueFerry — iPhone messages (iMessage/SMS/RCS), contacts and notifications on
# the Linux desktop, over a direct Bluetooth link to the phone.
#
# Not in nixpkgs, so this is a local derivation. Upstream only ships .deb/.rpm/
# .pkg.tar.zst built by hand-rolled shell scripts, and those hardcode /usr
# paths all over the Python source -- patching those out is most of what this
# file does.
#
# Upstream splits this into four packages (backend, gtk, qt, quickshell). We
# build the backend + the GTK4/libadwaita client only: Stylix themes GTK apps
# from the same base16 palette as the rest of the desktop, so the GTK client
# comes up dark with no per-app configuration. The Qt client would drag in
# pyside6 + kirigami, and the Quickshell one is written for Omarchy's bar.
#
# The system-level half (systemd units, the Class-of-Device polkit rule, the
# bluetoothd -E flag) lives in modules/system/blueferry.nix.
{
  lib,
  python3Packages,
  fetchFromGitHub,
  gtk4,
  libadwaita,
  libsecret,
  gobject-introspection,
  wrapGAppsHook4,
  bluez,
  systemd,
  wireplumber,
}:

python3Packages.buildPythonApplication rec {
  pname = "blueferry";
  version = "0.8.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "erikwb";
    repo = "blueferry";
    tag = "v${version}";
    hash = "sha256-Hk+SZYqxPYKo6DB1nsgA6WUD6xoh5ijyioRivkSM8yw=";
  };

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  dependencies = with python3Packages; [
    cryptography # >=42, storage encryption
    typer # >=0.12, the `blueferry` CLI
    dbus-python # talks to BlueZ and obexd
    pygobject3 # GTK4 bindings for the client
    textual # >=8.0, the `blueferry-tui` terminal client
  ];

  # gobject-introspection + wrapGAppsHook4 give the GTK client its typelibs and
  # GSettings/icon-theme environment. buildPythonApplication already wraps the
  # entry points, so let it do the wrapping once with the gapps env folded in
  # rather than having both hooks wrap the same scripts.
  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook4
  ];
  dontWrapGApps = true;

  buildInputs = [
    gtk4
    libadwaita
    libsecret # Secret Service client; KWallet provides the service here
  ];

  # Upstream assumes a filesystem-hierarchy distro. Every absolute path below
  # is dead on NixOS, and several are load-bearing: bluetooth_capabilities.py
  # shells out to btmgmt to read adapter capabilities, and bluez_setup.py uses
  # it to set the Class of Device that makes iOS offer the message/contact
  # permission toggles at all.
  postPatch = ''
    substituteInPlace \
        src/blueferry/bluez_setup.py \
        src/blueferry/bluetooth_capabilities.py \
      --replace-quiet '/usr/bin/btmgmt' '${bluez}/bin/btmgmt'

    # systemctl: --user unit restarts (daemon lifecycle) and reading
    # bluetooth.service's ExecStart during diagnostics.
    substituteInPlace \
        src/blueferry/bluez_setup.py \
        src/blueferry/bluetooth_capabilities.py \
        src/blueferry/backend_lifecycle.py \
        src/blueferry/wireplumber_policy.py \
        src/blueferry/pair_setup.py \
      --replace-quiet '/usr/bin/systemctl' '${systemd}/bin/systemctl'

    # WirePlumber: BlueFerry drops a config fragment that stops the iPhone
    # being claimed as an audio sink, which would fight with MAP over BR/EDR.
    substituteInPlace src/blueferry/wireplumber_policy.py \
      --replace-quiet '/usr/bin/wireplumber' '${wireplumber}/bin/wireplumber'

    # The daemon-binary probe: it stats these three paths to find bluetoothd
    # and read its version. Only the first is rewritten -- the other two stay
    # as harmless misses.
    substituteInPlace src/blueferry/bluetooth_capabilities.py \
      --replace-quiet '/usr/lib/bluetooth/bluetoothd' \
                      '${bluez}/libexec/bluetooth/bluetoothd'

    substituteInPlace src/blueferry/i18n.py \
      --replace-quiet '/usr/share/locale' "$out/share/locale"

    # Build identity and upgrade detection. Pointing package-release at $out
    # means every rebuild changes the store path, so the daemon notices a new
    # version and restarts itself instead of serving stale code.
    substituteInPlace src/blueferry/build_info.py \
      --replace-quiet '/usr/share/blueferry/build-sha' "$out/share/blueferry/build-sha"
    substituteInPlace src/blueferry/backend_lifecycle.py \
      --replace-quiet '/usr/share/blueferry/package-release' \
                      "$out/share/blueferry/package-release"

    # Notification click actions launch whichever client is installed.
    substituteInPlace src/blueferry/sinks/libnotify.py \
      --replace-quiet '/usr/bin/blueferry-gtk' "$out/bin/blueferry-gtk"

    # Interactive pairing runs in a separate process to keep its GLib main loop
    # and D-Bus connection away from the client's. Upstream spawns it as
    # `sys.executable -m blueferry`, which assumes the running interpreter can
    # import blueferry -- true when site-packages is global, false here.
    # nixpkgs makes dependencies importable with site.addsitedir() calls baked
    # into the *wrapped script*, not via PYTHONPATH, so a bare `sys.executable`
    # child gets "No module named blueferry", dies before emitting any JSON,
    # and every pairing attempt fails as "helper exited without a result".
    # Spawn our own wrapper instead; it sets the path up the same way the
    # parent got it. The assert makes this a build failure rather than a silent
    # no-op if upstream restructures the call.
    python3 - "$out" <<'PATCH_HELPER'
    import pathlib, sys
    out = sys.argv[1]
    path = pathlib.Path("src/blueferry/setup_client.py")
    source = path.read_text()
    old = '            sys.executable,\n            "-m",\n            "blueferry",\n'
    new = f'            "{out}/bin/blueferry",\n'
    assert old in source, "pairing helper spawn pattern not found; upstream changed"
    path.write_text(source.replace(old, new))
    PATCH_HELPER
  '';

  postInstall = ''
    # setuptools generates an entry point per [project.gui-scripts], including
    # the Qt client. We don't pull in pyside6/kirigami, so that script would be
    # an import error sitting on PATH -- drop it and its package directory.
    rm -f $out/bin/blueferry-qt
    rm -rf $out/${python3Packages.python.sitePackages}/blueferry/qt

    install -Dm644 data/io.weirdware.BlueFerry.Gtk.desktop \
      -t $out/share/applications
    install -Dm644 data/io.weirdware.BlueFerry.Gtk.metainfo.xml \
      -t $out/share/metainfo
    install -Dm644 data/icons/io.weirdware.BlueFerry.svg \
      -t $out/share/icons/hicolor/scalable/apps
    install -Dm644 data/io.weirdware.BlueFerry.xml \
      -t $out/share/dbus-1/interfaces

    # Session-bus activation. Clients talk to the bus name and systemd starts
    # the user unit on demand; written here rather than in the NixOS module
    # because it needs this derivation's own store path in Exec=.
    install -Dm644 /dev/stdin \
      $out/share/dbus-1/services/io.weirdware.BlueFerry.service <<EOF
    [D-BUS Service]
    Name=io.weirdware.BlueFerry
    Exec=$out/bin/blueferry run
    SystemdService=blueferry.service
    EOF

    # Read back by backend_lifecycle.py (see postPatch) to detect upgrades.
    install -d $out/share/blueferry
    echo "${version}-nix" > $out/share/blueferry/package-release

    # Helper for the privileged Class-of-Device unit in the NixOS module.
    # Class 4/8 is "Audio/Video, car audio" -- impersonating a car head unit is
    # what makes iOS expose the Message Notifications and Sync Contacts
    # toggles. btmgmt wants a pollable stdin even non-interactively (systemd
    # gives it /dev/null), hence the empty pipe.
    install -Dm755 /dev/stdin $out/libexec/blueferry-set-cod <<EOF
    #!/bin/sh
    set -eu
    case "\''${1-}" in
      "" | *[!0-9]*) echo "adapter index must be decimal digits" >&2; exit 64 ;;
    esac
    : | ${bluez}/bin/btmgmt --index "\$1" class 4 8
    EOF
  '';

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  # The upstream suite needs a private dbus-run-session with a fake BlueZ on
  # it; the packaging scripts drive that themselves. Just check the modules
  # import, which is what catches a missing runtime dependency.
  doCheck = false;
  pythonImportsCheck = [
    "blueferry"
    "blueferry.cli"
    "blueferry.daemon"
  ];

  meta = {
    description = "iPhone messages, contacts and notifications on Linux over Bluetooth";
    homepage = "https://github.com/erikwb/blueferry";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    mainProgram = "blueferry";
  };
}
