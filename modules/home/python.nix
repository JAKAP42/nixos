# The Python interpreter and its libraries.
#
# This gets its own module because it's the list that changes most often: keeping
# it here means "added scipy" is a one-line commit against a file that does
# nothing else.
#
# To add a library: put its name in the brackets below, then rebuild. Names come
# from the python3Packages set -- search with:
#   nix search nixpkgs python3Packages.<name>
#
# `pip install` does not work here, and not just because of this module -- it's
# blocked three ways on NixOS generally:
#   1. there is no `pip` on PATH (nixpkgs doesn't ship it with python3),
#   2. the stdlib carries a PEP 668 EXTERNALLY-MANAGED marker, so pip refuses,
#   3. ENABLE_USER_SITE is False and ~/.local/lib/python3.x/site-packages is not
#      on sys.path, so even `pip install --user` installs files Python won't import.
#
# Escape hatches, when you don't want to rebuild just to try something:
#   nix shell nixpkgs#python3Packages.<name>   # a real Nix package, throwaway shell
#   python3 -m venv .venv && .venv/bin/pip install <name>
#
# venvs are exempt from all three blocks above and do work. Caveat: pure-Python
# wheels are fine, but wheels with compiled extensions (numpy, scipy, ...) expect
# a standard FHS linker and will install happily then fail at import. Those belong
# in the list below, where Nix builds them against the right libraries.
{
  flake.homeModules.python =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.python3.withPackages (
          ps: with ps; [
            numpy
            requests
            matplotlib
            sounddevice
            scipy
          ]
        ))
      ];
    };
}
