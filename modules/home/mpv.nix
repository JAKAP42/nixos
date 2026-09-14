# Video playback: mpv as the engine, Haruna as the window with buttons.
#
# Before this module the system had no video player whatsoever -- Plasma6 ships
# Elisa, which is audio-only, so a double-clicked .mkv resolved to nothing and
# the only way to watch a file was to drag it into Firefox. That also made the
# gpu-screen-recorder clips (modules/home/gpu-screen-recorder.nix) awkward to
# review.
#
# Why both packages rather than one:
#
#   * mpv is the command line. `mpv file.mkv` from kitty, scripted playback,
#     piping a URL in. It reads ~/.config/mpv/mpv.conf, which is what the
#     `config` block below writes.
#   * Haruna is a Qt/KDE front-end that links libmpv -- the same decoder and
#     renderer, wrapped in a conventional GUI with a playlist, a seek bar and a
#     settings dialog. It is what the mime defaults point at, so double-clicking
#     a video gets a normal-looking player.
#
# The two share a decoding stack but NOT a config file: Haruna keeps its own
# settings in ~/.config/harunarc and offers the same knobs through its settings
# dialog. That file is deliberately left unmanaged here -- it is a KConfig file
# that Haruna rewrites whenever you change a setting in the GUI, so pointing a
# read-only Nix symlink at it would break the dialog. Set Haruna's preferences
# in Haruna; mpv.conf below only governs the CLI.
{
  flake.homeModules.mpv =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        haruna # GUI front-end (libmpv); the mime default, see modules/home/mime.nix
        yt-dlp # lets both players open a YouTube/stream URL directly
      ];

      programs.mpv = {
        enable = true;

        config = {
          # Hardware decoding. Deliberately "auto-safe" and not plain "auto":
          # auto-safe only considers backends from mpv's known-good list, which
          # means this one line is correct on both hosts without the module
          # having to know which machine it is on -- nvdec on home-machine's
          # GTX 1050 (Pascal, proprietary 580 driver) and VAAPI/radeonsi on the
          # AMD laptop. Set to "no" if you ever see decode artifacts.
          hwdec = "auto-safe";

          # gpu-next is the libplacebo-based renderer, and the one upstream now
          # develops against. Fall back to "gpu" if a driver update ever makes
          # playback black or glitchy.
          vo = "gpu-next";

          # Don't let the window vanish the instant a file ends -- mpv's default
          # is to quit, which is jarring when you only wanted to rewatch the
          # last few seconds of a recording.
          keep-open = "yes";

          # Remember the position in a file and resume there next time. State
          # lands in ~/.local/state/mpv/watch_later, not in this repo.
          save-position-on-quit = true;

          # Pick up sidecar subtitle files whose name merely resembles the
          # video's ("fuzzy"), rather than requiring an exact match.
          sub-auto = "fuzzy";

          # 100 is unity gain; the headroom above it rescues quiet sources.
          volume = 70;
          volume-max = 150;

          # Screenshots (the `s` key) as lossless PNG, out of the way of the
          # video's own directory, which is where mpv would otherwise drop them.
          screenshot-format = "png";
          screenshot-directory = "~/Pictures/mpv";
        };
      };
    };
}
