# Minecraft Java Edition, via Prism Launcher.
#
# Prism rather than the official launcher (pkgs.minecraft), which is an
# FHS-wrapped bootstrap that self-updates and fetches its own native libraries
# at runtime -- the pattern NixOS handles worst. Prism is packaged natively and
# the wrapper injects PRISMLAUNCHER_JAVA_PATHS with four JDKs (8, 17, 21, 25),
# so Java is not a thing you manage: auto-detect is on by default and matches
# each instance to the version its manifest asks for (26.x wants 25; the older
# JDKs are for older instances). Resist pinning a Java path in Prism's settings,
# per-instance or globally -- it saves an absolute store path that breaks on the
# next flake update, whereas auto-detect re-reads the env var the wrapper
# regenerates each rebuild. Leave Prism's "download the Java build recommended
# by Mojang" option off too: Mojang's JRE is a stock glibc binary and won't run
# unpatched.
#
# A *system* module, not a home one, for the same reason as localsend: the
# package alone half-works. LAN discovery is a multicast ping to
# 224.0.2.60:4445 and the game only sees worlds it can receive those on, which
# the default-on firewall drops. Keep the package and the port together.
#
# Join-only. Hosting an "Open to LAN" world also needs an inbound TCP port, and
# the integrated server picks a random one per session, so that means pinning a
# port in-game plus a rule here. Add it when you want to host.
#
# Opens on every interface, eduroam included -- see localsend.nix if you'd
# rather scope it to one network.
{
  flake.nixosModules.minecraft =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.prismlauncher ];

      networking.firewall.allowedUDPPorts = [ 4445 ];
    };
}
