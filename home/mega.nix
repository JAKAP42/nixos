{ pkgs, ... }:
{
  # MEGA cloud storage (20 GB free), mounted on demand at ~/MEGA — same idea
  # as the OneDrive mount: everything shows in Dolphin, nothing is downloaded
  # until you open it.
  #
  # ONE-TIME SETUP (after signing up at https://mega.nz and rebuilding):
  #   rclone config
  #     n) New remote
  #     name> mega              <-- must be exactly this name
  #     Storage> mega           (search the list for "Mega")
  #     user> your MEGA email
  #     pass> y, then type your MEGA password
  #     Edit advanced config> n
  #     ...then y) Yes this is OK, q) Quit
  # Then start the mount:
  #   systemctl --user restart rclone-mega
  # Finally drag ~/MEGA into Dolphin's "Places" sidebar (or add it via
  # right-click empty sidebar space -> "Add Entry...").

  systemd.user.services.rclone-mega = {
    Unit = {
      Description = "Mount MEGA on demand with rclone";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/MEGA";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount mega: %h/MEGA \
          --vfs-cache-mode full \
          --vfs-cache-max-size 5G \
          --vfs-cache-max-age 168h \
          --dir-cache-time 24h \
          --umask 022
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -uz %h/MEGA";
      Restart = "on-failure";
      RestartSec = "10";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
