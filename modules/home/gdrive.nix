{
  flake.homeModules.gdrive =
    { pkgs, ... }:
    {
      # Google Drive (15 GB free), mounted on demand at ~/GoogleDrive — same idea
      # as the OneDrive and MEGA mounts: everything shows in Dolphin, nothing is
      # downloaded until you open it.
      #
      # ONE-TIME SETUP (after rebuilding):
      #   rclone config
      #     n) New remote
      #     name> gdrive            <-- must be exactly this name
      #     Storage> drive          (search the list for "Google Drive")
      #     client_id / secret> just press Enter (leave blank)
      #     scope> 1                (full access to all files)
      #     service_account_file> press Enter
      #     Edit advanced config> n
      #     Use auto config> y      (a browser opens — log in to Google)
      #     Shared Drive> y         then pick the drive from the list rclone shows
      #     ...then y) Yes this is OK, q) Quit
      #
      # This remote points at a Shared Drive, so ~/GoogleDrive shows that drive
      # only — personal "My Drive" would need a second remote without the
      # Shared Drive step.
      #
      # --drive-export-formats link.html: Google reports no file size for native
      # Docs/Sheets/Slides, so under the default export formats they surface as
      # unreadable 0-byte .docx/.xlsx files. Rclone can't write edits back into a
      # native doc either, so instead they become small .html files that open the
      # doc in the browser. Real uploaded files are unaffected. To get an offline
      # copy of a native doc: rclone copy "gdrive:path/Name.docx" .
      # Then start the mount:
      #   systemctl --user restart rclone-gdrive
      # Finally drag ~/GoogleDrive into Dolphin's "Places" sidebar.
      #
      # Leaving client_id blank uses rclone's shared Google API key, which is
      # rate-limited across all rclone users — fine for normal use, but if
      # transfers crawl, make your own at https://rclone.org/drive/#making-your-own-client-id

      systemd.user.services.rclone-gdrive = {
        Unit = {
          Description = "Mount Google Drive on demand with rclone";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Service = {
          Type = "notify";
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive";
          ExecStart = ''
            ${pkgs.rclone}/bin/rclone mount gdrive: %h/GoogleDrive \
              --drive-export-formats link.html \
              --vfs-cache-mode full \
              --vfs-cache-max-size 5G \
              --vfs-cache-max-age 168h \
              --dir-cache-time 24h \
              --umask 022
          '';
          ExecStop = "${pkgs.fuse}/bin/fusermount -uz %h/GoogleDrive";
          Restart = "on-failure";
          RestartSec = "10";
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
