# Interactive shell config (bash) and its aliases. Aliases live here rather
# than in ~/.bashrc so they are declarative like everything else -- edit this
# file, rebuild, then open a new terminal for them to take effect.
#
# Note: enabling programs.bash lets Home Manager own ~/.bashrc. The first
# rebuild moves any existing hand-written one to ~/.bashrc.hm-bak.
{
  flake.homeModules.shell =
    { ... }:
    {
      programs.bash = {
        enable = true;

        shellAliases = {
          # Apply this config -- the command from README.md "Apply changes".
          # `#$(hostname)` picks the nixosConfiguration matching THIS machine
          # (nixos on the laptop, home-machine on the desktop), so the same
          # alias is correct on every host.
          rebuild = "sudo nixos-rebuild switch --flake ~/nixos#$(hostname)";
          # Same, but only for the next boot (doesn't touch the running system).
          rebuild-boot = "sudo nixos-rebuild boot --flake ~/nixos#$(hostname)";
          # Build and check without making it the active generation.
          rebuild-test = "sudo nixos-rebuild test --flake ~/nixos#$(hostname)";
        };
      };
    };
}
