# Proton VPN: the official client, for general-purpose tunnelling.
#
# Unrelated to the NTNU tunnel in ../base.nix -- that one is openconnect over
# Cisco AnyConnect and only gets you onto NTNU's network. This is the ordinary
# "hide the traffic from the network I'm on" kind.
#
# The app manages its own connections through NetworkManager, so it coexists
# with the NTNU entry rather than fighting it; only don't expect both tunnels
# up at once. Log in once in the GUI -- credentials land in the Secret Service
# keyring, which under Hyprland is the ksecretd activation set up in
# ./desktop.nix, so no extra keyring daemon is needed here.
#
# The free tier is account-limited, not client-limited: one device at a time,
# a handful of countries, server picked for you, no P2P. Nothing in this module
# changes if the account is later upgraded.
{
  flake.nixosModules.protonvpn =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Renamed from `protonvpn-gui` upstream; the old name still evaluates
        # but warns. Ships both the GTK app ("Proton VPN") and the tray icon
        # that waybar's tray module picks up.
        proton-vpn
      ];

      # WireGuard is the app's default and NetworkManager speaks it natively,
      # but the protocol dropdown also offers OpenVPN (UDP/TCP) -- useful on
      # networks that block WireGuard's UDP. That path needs the NM plugin;
      # without it the option is there and silently fails to connect.
      networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
    };
}
