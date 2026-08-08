{ pkgs, ... }:
{
  # On-demand OneDrive, the same way Windows does it ("Files On-Demand").
  #
  # rclone mounts your whole OneDrive as a folder at ~/OneDrive. Everything
  # shows up in Dolphin, but nothing is downloaded until you actually open a
  # file — so it costs almost no disk space. Files you open are cached locally
  # (up to the size limit below) and any edits sync back to the cloud.
  #
  # ONE-TIME SETUP (after the first rebuild, do this once in a terminal):
  #   rclone config
  #     n) New remote
  #     name> onedrive          <-- must be exactly this name
  #     Storage> onedrive       (search the list for "Microsoft OneDrive")
  #     client_id / secret> just press Enter (leave blank)
  #     Edit advanced config> n
  #     Use auto config> y      (a browser opens — log in to Microsoft)
  #     Choose account type> 1  (OneDrive Personal)
  #     ...accept the defaults, then y) Yes this is OK, q) Quit
  # Then start the mount:
  #   systemctl --user restart rclone-onedrive
  # Finally drag ~/OneDrive into Dolphin's "Places" sidebar to pin it.

  home.packages = [ pkgs.rclone ];

  systemd.user.services.rclone-onedrive = {
    Unit = {
      Description = "Mount OneDrive on demand with rclone";
      # Wait for the network before trying to mount.
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "notify";
      # Make sure the mount point exists before mounting into it.
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/OneDrive";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount onedrive: %h/OneDrive \
          --vfs-cache-mode full \
          --vfs-cache-max-size 5G \
          --vfs-cache-max-age 168h \
          --dir-cache-time 24h \
          --umask 022
      '';
      # Cleanly unmount when the service stops.
      ExecStop = "${pkgs.fuse}/bin/fusermount -uz %h/OneDrive";
      # If it fails (e.g. before you've run `rclone config`), keep retrying.
      Restart = "on-failure";
      RestartSec = "10";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
