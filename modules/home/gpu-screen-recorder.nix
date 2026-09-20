# The user-facing half of GPU Screen Recorder: one toggle command bound to a
# key, and the status probe the waybar indicator polls. The recorder itself and
# its capability wrapper come from modules/system/gpu-screen-recorder.nix — that
# part has to be system-level, this part doesn't.
#
# Why two scripts rather than a raw `gpu-screen-recorder` line in the keybind:
# starting is a long command with a timestamped filename, stopping is a signal
# to an existing process, and the bar needs to know which of the two states
# we're in. Wrapping that in `gsr-toggle` keeps one key doing the obvious thing.
#
# Both scripts hinge on "is a recording live right now", and that question is
# answered by PID, recorded in a runtime state file. The obvious alternative —
# looking the process up by name — is a trap worth documenting so nobody
# reintroduces it:
#
#   * Linux truncates process names to 15 characters, so `gpu-screen-recorder`
#     appears in /proc as `gpu-screen-reco`. Anything matching the exact name
#     (pgrep -x, and pidof when the binary sits behind a wrapper script) finds
#     nothing at all.
#   * Falling back to matching the whole command line then over-matches: plain
#     `-f gpu-screen-recorder` also hits gpu-screen-recorder-gtk, so merely
#     having the GUI open would light up the indicator and a stop would kill the
#     window — and any stray shell that happens to mention the name becomes a
#     target for `pkill` too. That is not theoretical; it killed a shell during
#     testing of this module.
#
# Signalling a PID we recorded ourselves has neither problem. The state file is
# self-healing: if the recorder ever dies on its own the PID stops responding,
# both scripts fall back to "not recording", and the next start overwrites it.
#
# Trade-off worth knowing: a recording started from the GTK GUI rather than the
# keybind writes no state file, so the bar won't show REC for it. The keybind is
# the supported path; the GUI has its own window to tell you it's running.
{
  flake.homeModules.gpuScreenRecorder =
    { pkgs, ... }:
    let
      stateFile = ''''${XDG_RUNTIME_DIR:-/tmp}/gsr-current-recording'';

      # Shared by both scripts, so the two can never disagree about what
      # "recording" means. Sets $gsrFile and returns 0 when a recording is live.
      gsrLookup = ''
        state="${stateFile}"

        gsr_running() {
            gsrPid="" gsrFile=""
            [ -r "$state" ] || return 1
            # gsrFile is read for callers that report the path; gsr-waybar only
            # wants the yes/no, so shellcheck sees it unused there.
            # shellcheck disable=SC2034
            { read -r gsrPid; read -r gsrFile || true; } < "$state"
            case "$gsrPid" in "" | *[!0-9]*) return 1 ;; esac
            kill -0 "$gsrPid" 2> /dev/null || return 1
            # Guards against the PID having been recycled by an unrelated
            # process. 'gpu-screen-reco' is the 15-character truncation the
            # kernel stores; comparing the full name here would never match.
            [ "$(cat /proc/"$gsrPid"/comm 2> /dev/null)" = "gpu-screen-reco" ] || return 1
        }
      '';

      # Nudge waybar to re-run the status probe immediately, so the indicator
      # appears and disappears on the keypress rather than up to a poll later.
      # waybar's custom modules listen on SIGRTMIN+<signal>, and the number here
      # must stay in step with `signal = 8` in modules/home/waybar.nix. The name
      # match is deliberately loose: home-manager's waybar runs as
      # `.waybar-wrapped`, which a bare `pkill waybar` still matches.
      refreshBar = "pkill -RTMIN+8 waybar || true";

      gsrToggle = pkgs.writeShellApplication {
        name = "gsr-toggle";
        runtimeInputs = with pkgs; [
          procps # pkill, for the waybar refresh
          libnotify # notify-send, rendered by mako
          coreutils # date, mkdir, basename, cat
          # Pinned rather than taken from ambient PATH. Safe despite the setcap
          # wrapper: nixpkgs' own wrapper around this binary prepends
          # /run/wrappers/bin, so it still picks up the capability-carrying
          # gsr-kms-server that the system module installs.
          gpu-screen-recorder
        ];
        text = ''
          ${gsrLookup}

          if gsr_running; then
              # SIGINT is GSR's "finish the file cleanly" signal — it flushes and
              # closes the container. Killing it any harder leaves a broken file.
              kill -INT "$gsrPid"
              rm -f "$state"
              notify-send -t 3000 -u low -- "Recording stopped" \
                  "Saved ''${gsrFile:-to $HOME/Videos}"
              ${refreshBar}
          else
              dir="$HOME/Videos"
              mkdir -p "$dir"
              file="$dir/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"

              # $$ is the PID the recorder will have, because of the exec below.
              printf '%s\n%s\n' "$$" "$file" > "$state"

              notify-send -t 2000 -u low -- "Recording started" "$(basename "$file")"
              ${refreshBar}

              # Deliberately `exec` rather than backgrounding with `&`, for two
              # reasons. It makes the recorder inherit this script's PID, which
              # is what the state file just claimed. And a shell that isn't
              # interactive starts background jobs with SIGINT set to ignored,
              # which the child inherits — that would leave the stop branch
              # above signalling a recorder that cannot hear it.
              #
              # -w screen: the first monitor (this laptop only has the one).
              # -a default_output: whatever is currently playing, so game and
              # call audio land in the recording without extra setup.
              # -q/-bm: constant quality rather than constant bitrate, which is
              # the right trade for recording to disk (CBR is for streaming).
              # -c mp4 -ac aac: chosen so recordings can go straight to the
              # phone. iOS Photos rejects mkv outright — LocalSend drops it in
              # Files instead — and it can't read opus, which is what GSR
              # defaults to for mkv and mp4 alike. H.264 + AAC in mp4 is the
              # combination Photos accepts, and it costs nothing here: the
              # encoder settings above are unchanged, only the wrapper differs.
              #
              # mkv would normally be the safer container, since a plain mp4 is
              # unplayable if the recorder dies before writing its index. That
              # doesn't apply to GSR, which writes fragmented mp4 (see its
              # hybrid_fragmented movflags handling) and stays playable.
              #
              # -fm cfr: GSR defaults to vfr, whose jittery frame timestamps
              # make Kdenlive treat recordings as variable frame rate — it
              # prompts to transcode, and audio drifts if you decline. Costs
              # nothing here; clips measured at exactly 60.000 fps either way.
              exec gpu-screen-recorder -w screen -f 60 -a default_output \
                  -q very_high -bm qp -c mp4 -ac aac -fm cfr -o "$file"
          fi
        '';
      };

      # Printed for waybar, which expects one JSON object per run. Empty text
      # hides the module, so the bar shows nothing at all unless recording.
      gsrWaybar = pkgs.writeShellApplication {
        name = "gsr-waybar";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          ${gsrLookup}

          if gsr_running; then
              printf '{"text":"  REC","class":"recording","tooltip":"Recording — SUPER + ALT + F to stop and save"}\n'
          else
              printf '{"text":""}\n'
          fi
        '';
      };
    in
    {
      home.packages = [
        gsrToggle
        gsrWaybar
      ];
    };
}
