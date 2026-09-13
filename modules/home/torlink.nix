# torlink: a terminal torrent finder/downloader. Runs as `torlnk`.
#
# Not packaged in nixpkgs, so it comes from upstream's own flake (see the
# `torlink` input in ../../flake.nix). The catch: upstream's nix/package.nix
# is maintained separately from their npm releases and currently still pins
# version 1.4.1, four tags behind what they publish. Torrent-site scrapers rot
# quickly, so running the stale one means sources quietly going dead. This
# module therefore takes their derivation -- all the awkward parts, the
# node-datachannel WebRTC build against nixpkgs' openssl and the clipboard
# wrapping, are theirs and unchanged -- and points it at the current tag.
#
# To bump: set `version` below, then get the two hashes.
#   src:      nix-prefetch-url --unpack https://github.com/baairon/torlink/archive/refs/tags/v<VER>.tar.gz
#             nix hash convert --hash-algo sha256 --to sri <result>
#   npmDeps:  curl -sSLO https://raw.githubusercontent.com/baairon/torlink/v<VER>/package-lock.json
#             nix run nixpkgs#prefetch-npm-deps -- ./package-lock.json
#
# When upstream's package.nix finally catches up past this version, delete the
# whole override and use `inputs.torlink.packages.${pkgs.system}.default` bare.
{ inputs, ... }:
{
  flake.homeModules.torlink =
    { pkgs, ... }:
    let
      version = "1.8.0";

      src = pkgs.fetchFromGitHub {
        owner = "baairon";
        repo = "torlink";
        tag = "v${version}";
        hash = "sha256-1mpbEFzEO0p+yzTM8mMui646FKFl3ENQP1L8yYP5O/Y=";
      };

      torlink = inputs.torlink.packages.${pkgs.system}.default.overrideAttrs (prev: {
        inherit version src;

        # buildNpmPackage turns `npmDepsHash` into this fixed-output derivation
        # before mkDerivation ever sees it, so overriding the hash attribute
        # alone would do nothing -- the dependency cache has to be rebuilt from
        # the new lockfile here.
        npmDeps = pkgs.fetchNpmDeps {
          inherit src;
          name = "${prev.pname}-${version}-npm-deps";
          hash = "sha256-/oNsIPG86av1xnKiLcFeiJj88cMnu3ugNKGKeXI3fUE=";
        };
      });
    in
    {
      home.packages = [ torlink ];
    };
}
