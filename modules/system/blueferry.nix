# BlueFerry — the iPhone's messages (iMessage, SMS, RCS), contacts and
# notifications on this desktop, over a direct Bluetooth link to the phone.
#
# Why this works at all: iOS has no API that lets a third-party app read the
# Messages database, which is why KDE Connect can't do this and why BlueBubbles
# needs a Mac sitting in the middle. BlueFerry sidesteps the whole problem by
# not running on the phone. It impersonates a *car stereo* -- the MAP (Message
# Access) and PBAP (Phonebook Access) Bluetooth profiles Apple deliberately
# exposes so head units can read texts aloud. ANCS over Bluetooth LE supplies
# the notification stream on top.
#
# Three consequences worth understanding before relying on it:
#   - The phone must be in Bluetooth range. This is a companion to the phone,
#     not a standalone client -- walk away from the desk and it stops.
#   - There is no history import. It only knows messages seen since pairing.
#   - No attachments, reactions, typing indicators, or calls. Group chats are
#     approximate, because MAP has no reliable group identifier.
# Upstream calls it alpha and says not to make it your only path for an
# important message. Treat it as a convenience, not as Messages-on-Mac.
#
# The package (backend + GTK client) is built from pkgs/blueferry.nix; it isn't
# in nixpkgs. This module is the system-level half: the parts that need root or
# that have to agree with the rest of the Bluetooth stack.
{ self, ... }:
{
  flake.nixosModules.blueferry =
    { config, lib, pkgs, ... }:
    let
      blueferry = pkgs.callPackage (self + "/pkgs/blueferry.nix") { };
      bluezPkg = config.hardware.bluetooth.package;
    in
    {
      environment.systemPackages = [ blueferry ];

      # Ships the session-bus activation file, so the daemon starts on demand
      # when a client first talks to io.weirdware.BlueFerry.
      services.dbus.packages = [ blueferry ];

      # BlueFerry needs BlueZ's per-transport Bearer.LE1/Bearer.BREDR1
      # interfaces so it can hold ANCS on LE while MAP/PBAP run over BR/EDR.
      # Those are behind BlueZ's experimental flag.
      #
      # desktop.nix already sets hardware.bluetooth.settings.General.Experimental
      # (for headset battery reporting), and for BlueZ itself that is equivalent
      # to -E. But BlueFerry's own diagnostics read /proc/<pid>/cmdline looking
      # for a literal -E / --experimental, so without this override a working
      # setup reports itself as broken. Passing the flag explicitly makes the
      # daemon and the checker agree; it enables nothing that main.conf hadn't
      # already turned on.
      #
      # mkForce because serviceConfig values of list type *concatenate* rather
      # than replace: without it this appends a second ExecStart=/ExecStart=
      # pair after the nixpkgs one. systemd would still end up running the
      # right command (each empty ExecStart= resets the list), but the unit
      # reads as though it has two definitions. Replace it outright instead.
      systemd.services.bluetooth.serviceConfig.ExecStart = lib.mkForce [
        ""
        "${bluezPkg}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf -E"
      ];

      # The daemon. One per user, talking to BlueZ over D-Bus. The condition is
      # upstream's: the unit is enabled for everyone, but only a user who has
      # actually completed pairing has a local.env and should start a daemon.
      systemd.user.services.blueferry = {
        description = "BlueFerry — iPhone↔Linux Bluetooth bridge";
        documentation = [ "https://github.com/erikwb/blueferry" ];
        wantedBy = [ "default.target" ];
        unitConfig.ConditionPathExists = "%h/.config/blueferry/local.env";

        serviceConfig = {
          Type = "dbus";
          BusName = "io.weirdware.BlueFerry";
          ExecStart = "${blueferry}/bin/blueferry run";
          Restart = "on-failure";
          # EX_TEMPFAIL is how the daemon asks to be restarted after an upgrade.
          RestartForceExitStatus = 75;
          RestartSec = 5;
          # Lets one in-flight Bluetooth transfer finish; OBEX transfers are
          # bounded at 120s.
          TimeoutStopSec = 180;
          UMask = "0077";

          # Upstream's sandbox, kept verbatim. MemoryDenyWriteExecute is
          # deliberately absent: PyGObject/dbus-python use libffi trampolines.
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RestrictNamespaces = true;
          SystemCallArchitectures = "native";
          # Bluetooth is reached purely through local D-Bus sockets -- no IP,
          # no raw AF_BLUETOOTH.
          RestrictAddressFamilies = "AF_UNIX";
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
        };
      };

      # Setting the adapter's Class of Device to 4/8 (Audio/Video, car audio)
      # is the piece that makes iOS offer "Show Message Notifications" and
      # "Sync Contacts" on the ⓘ page. It needs CAP_NET_ADMIN, and the kernel
      # forgets it across adapter resets, so the user daemon has to be able to
      # re-apply it -- hence a tiny system unit plus the polkit rule below.
      systemd.services."blueferry-btmgmt-set-class@" = {
        description = "BlueFerry: set Bluetooth adapter hci%i class";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${blueferry}/libexec/blueferry-set-cod %i";
          NoNewPrivileges = true;
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_NET_RAW"
          ];
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RestrictAddressFamilies = "AF_BLUETOOTH";
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
        };
      };

      # Narrow grant: an active local session may start that one templated
      # unit, and nothing else. The unit has a fixed command, validates its
      # argument is a decimal adapter index, and can only ever set class 4/8 --
      # so this is not a general "run btmgmt as root" or "manage any unit"
      # delegation. Without it the user gets an auth prompt on every reset.
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
            if (action.id !== "org.freedesktop.systemd1.manage-units" ||
                action.lookup("verb") !== "start" ||
                !subject.active || !subject.local) {
                return polkit.Result.NOT_HANDLED;
            }
            var unit = action.lookup("unit");
            if (unit && /^blueferry-btmgmt-set-class@[0-9]+\.service$/.test(unit)) {
                return polkit.Result.YES;
            }
            return polkit.Result.NOT_HANDLED;
        });
      '';
    };
}
