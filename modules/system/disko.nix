# Declarative disk layout (disko). A host that imports this module gets its
# `userconf.disk` partitioned and formatted from the spec below, and the
# fileSystems entries for / and /boot are generated automatically — no
# hand-written hardware-configuration.nix UUIDs. Only hosts that list `disko`
# in their module set are affected (the 'nixos' laptop does not, so it keeps
# its committed hardware-configuration.nix untouched).
#
# Layout on the target disk (GPT):
#   512M  ESP   vfat  -> /boot
#     8G  swap
#   rest  ext4        -> /
#
# NOTE: this only ever touches `/dev/${userconf.disk}`. /home lives on a
# separate disk and is mounted in the host module, not here, so disko never
# formats it.
{ inputs, ... }:
{
  flake.nixosModules.disko =
    { userconf, ... }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      disko.devices.disk.main = {
        device = "/dev/${userconf.disk}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # priority forces creation order: fixed-size partitions first, then
            # the 100% root last (Nix sorts attrs alphabetically, which would
            # otherwise let root claim the whole disk before swap is cut).
            ESP = {
              priority = 1;
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              priority = 2;
              size = "8G";
              content = {
                type = "swap";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
}
