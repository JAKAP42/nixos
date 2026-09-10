# LocalSend — an AirDrop-style file transfer that works between this PC, the
# phone and the iPad, with no account and no cloud in the middle. Devices find
# each other by UDP multicast on the local subnet and then transfer directly
# over HTTPS (self-signed certs, generated per device), so nothing leaves the
# network and it works with the internet down.
#
# This has to be a *system* module rather than a home one. The package itself
# would be fine in home.packages, but LocalSend only works if the rest of the
# LAN can reach this machine on port 53317, and NixOS enables its firewall by
# default — nothing else in this tree touches networking.firewall. Installing
# the app alone gets you a half-working setup: sending from the PC succeeds,
# and the PC is invisible to every other device. programs.localsend does both
# halves (openFirewall defaults to true and opens 53317 on TCP and UDP).
#
# Consequence worth knowing: the port is open on every interface, including
# eduroam and other untrusted networks. LocalSend still requires you to accept
# each incoming transfer on this end, so an open port means "discoverable",
# not "writable" — but if you'd rather it only listen at home, drop
# openFirewall and add the port under a per-interface
# networking.firewall.interfaces.<name> instead.
#
# Other devices need the app too: App Store for the iPad and iPhone, F-Droid or
# Play Store on Android, localsend.org for Windows/macOS.
#
# Ad-hoc transfers only — this is not a sync tool. Folders that should stay
# mirrored belong in the onedrive/mega rclone mounts.
{
  flake.nixosModules.localsend =
    { ... }:
    {
      programs.localsend.enable = true;
    };
}
