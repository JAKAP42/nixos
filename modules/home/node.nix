# Node.js, npm and npx.
#
# Pinned to the 24.x LTS line rather than plain `nodejs` so the version doesn't
# move under you when nixpkgs bumps its default -- projects here (gods-eye-view
# wants 24.x or 26.x) tend to care about the major.
#
# Unlike python.nix there is no library list to maintain: npm installs a project's
# dependencies into its own ./node_modules, so per-project deps never come from
# Nix. This module only provides the interpreter and the package manager.
#
# `npm install` (local, inside a project) works fine. `npm install -g` does not,
# out of the box: npm's default prefix is the nodejs derivation in /nix/store,
# which is read-only. The sessionVariables below repoint the global prefix at a
# writable dir in $HOME and put its bin/ on PATH, so `-g` behaves normally.
# Things installed that way are of course not tracked by Nix -- for anything you
# want to keep, prefer adding the nixpkgs package to home.packages instead.
#
# The NixOS-specific failure mode to know about: npm packages that ship prebuilt
# native binaries expect /lib64/ld-linux-x86-64.so.2, which does not exist here,
# so they die with "no such file or directory" naming a file that plainly is
# there. Vite/esbuild are statically linked Go and unaffected. When it does bite,
# the fixes are, in order of preference: the nixpkgs package, a nix-shell with
# the needed libs, or `pkgs.buildFHSEnv`.
{
  flake.homeModules.node =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.nodejs_24 ];

      # Global installs go here instead of the read-only store path.
      home.sessionVariables.npm_config_prefix = "$HOME/.npm-global";
      home.sessionPath = [ "$HOME/.npm-global/bin" ];
    };
}
