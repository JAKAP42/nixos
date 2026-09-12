# KDE Connect — pairs the phone with this PC over the LAN and then bridges the
# two: the phone's screen becomes a touchpad and presentation remote for the PC,
# clipboard is shared, files/links can be pushed in either direction ("Share" on
# the phone, right-click → Send via KDE Connect here), and the phone can trigger
# commands on the PC.
#
# What you get depends on the phone, and the iOS app is the weaker half. On
# Android it also mirrors notifications into mako, bridges SMS, and pauses media
# on an incoming call; on iOS/iPadOS none of that is possible (Apple forbids
# reading notifications and kills background services), and even clipboard sync
# is unreliable there because the app has to be in the foreground. So on an
# iPhone this is really just the remote-input, share and run-command features.
#
# Overlaps with localsend.nix on the ad-hoc file transfer part. Keep both:
# LocalSend needs no pairing and behaves identically on every device, while KDE
# Connect adds the remote-control side LocalSend has no concept of.
#
# A *system* module, for the same reason LocalSend is: the app alone gets you a
# half-working setup. Devices find each other by UDP broadcast on port 1716 and
# then hold a TLS connection on a port in 1714-1764, so the NixOS firewall
# (enabled by default) has to let that range through in both directions or the
# phone never sees this machine. programs.kdeconnect does both halves: installs
# kdePackages.kdeconnect-kde and opens 1714-1764 on TCP and UDP.
#
# Same caveat as LocalSend: the range is open on every interface, eduroam
# included. Pairing requires explicit confirmation on both ends and everything
# after that is TLS with pinned per-device certs, so an open port means
# "reachable", not "trusted" — but if you'd rather it only listen at home, drop
# this module and hand-roll the ranges under
# networking.firewall.interfaces.<name>.
#
# The daemon (kdeconnectd) is D-Bus activatable, but nothing would ever activate
# it under Hyprland, and a daemon that isn't running is a PC the phone can't
# find. modules/home/hyprland.nix execs `kdeconnect-indicator` at session start,
# which starts the daemon and puts a tray icon in waybar — that's the half of
# this feature that lives on the home side.
#
# The phone needs the app too: "KDE Connect" on F-Droid or the Play Store. Then
# open it on both ends while on the same Wi-Fi, and accept the pairing request.
{
  flake.nixosModules.kdeconnect =
    { ... }:
    {
      programs.kdeconnect.enable = true;
    };
}
