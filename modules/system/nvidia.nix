# NVIDIA proprietary driver, for hosts with an NVIDIA GPU (e.g. the
# 'home-machine' desktop's GeForce GTX 1050 / Pascal). Only hosts that list
# `nvidia` in their module set get this; the AMD laptop does not.
#
# `open = false` because the open kernel modules only support Turing (RTX 20xx)
# and newer — Pascal needs the closed module. modesetting is required for the
# Wayland/Hyprland session to drive the card.
{
  flake.nixosModules.nvidia =
    { config, ... }:
    {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.graphics.enable = true;

      hardware.nvidia = {
        modesetting.enable = true;
        open = false;
        nvidiaSettings = true;
        # Desktop, always on AC — the runtime power management (fine-grained
        # suspend of the GPU) is aimed at laptops and is a common source of
        # wake-from-suspend glitches, so leave it off here.
        powerManagement.enable = false;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };
}
