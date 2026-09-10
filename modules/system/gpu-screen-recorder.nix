# GPU Screen Recorder — screen/game capture that encodes on the GPU instead of
# pushing frames through the CPU. On this machine that means the Renoir iGPU's
# VAAPI encoder (H.264/HEVC); the frames never make the round trip to system
# RAM, so the FPS cost while recording is a few percent rather than the
# noticeably larger hit OBS takes for the same capture.
#
# Day-to-day use is the SUPER+ALT+F toggle wired up in
# modules/home/gpu-screen-recorder.nix: press to record, press again to save.
# The other thing this tool can do is a replay buffer — hold the last N seconds
# in memory and only write a file when asked, so you can save something that
# already happened. Nothing else on Linux really does this, but it isn't bound
# to a key here on purpose; reach for it through the GUI if it's ever wanted.
#
# This has to be a *system* module, not a home one. Capturing a monitor on
# Wayland goes through KMS, which needs CAP_SYS_ADMIN — with a plain
# home.packages install every recording either fails or prompts for a password.
# programs.gpu-screen-recorder builds a setcap wrapper in /run/wrappers/bin so
# recording starts silently. That capability is the whole reason the option
# exists; it can't be reproduced from the home side.
#
# Deliberately not a replacement for OBS. There are no scenes, overlays,
# webcam-in-corner or filters here — this captures, it doesn't produce. The two
# use separate capture paths and coexist fine, so if editing/streaming ever
# comes up, add OBS alongside it rather than swapping this out.
{
  flake.nixosModules.gpu-screen-recorder =
    { pkgs, ... }:
    {
      programs.gpu-screen-recorder.enable = true;

      # The GUI, which is a front end over the CLI above rather than a separate
      # recorder — it shells out to the wrapped binary. It lives here instead of
      # in the home `apps` module so that both halves of the feature stay in one
      # file; installed on its own it would silently lose the capability wrapper
      # and be unable to record a monitor.
      environment.systemPackages = with pkgs; [ gpu-screen-recorder-gtk ];
    };
}
