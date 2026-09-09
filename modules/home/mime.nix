# Default applications per file type (the XDG "mimeapps.list"). This is what
# decides which program opens when you double-click a file or an app calls
# `xdg-open`. Managed here so it survives rebuilds instead of drifting.
#
# Note: Home Manager takes ownership of ~/.config/mimeapps.list, so anything a
# GUI app writes there ("always open with...") gets replaced on the next
# rebuild. Add it to the list below instead.
{
  flake.homeModules.mime =
    { ... }:
    {
      xdg.mimeApps = {
        enable = true;

        # "Added Associations" = extra apps allowed to handle a type, beyond
        # what their own MimeType= line claims. Firefox's desktop entry never
        # advertises application/pdf even though pdf.js opens PDFs fine, so
        # this is what keeps it offered as a choice for "Open With".
        associations.added = {
          "application/pdf" = [ "firefox.desktop" ];
        };

        defaultApplications = {
          # PDFs open in Okular (ships with the plasma6 fallback session, and
          # declares application/pdf itself so it needs no patching).
          # Swap for "onlyoffice-desktopeditors.desktop" to edit the text, or
          # "firefox.desktop" for a browser.
          "application/pdf" = [ "okularApplication_pdf.desktop" ];

          # Office documents open in ONLYOFFICE (installed from apps.nix). It
          # also advertises application/pdf, but the explicit Okular default
          # above wins, so PDFs are unaffected.
          #
          # Word.
          "application/msword" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.text" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/rtf" = [ "onlyoffice-desktopeditors.desktop" ];

          # Excel.
          "application/vnd.ms-excel" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.spreadsheet" = [ "onlyoffice-desktopeditors.desktop" ];

          # PowerPoint.
          "application/vnd.ms-powerpoint" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.presentationml.slideshow" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.presentation" = [ "onlyoffice-desktopeditors.desktop" ];

          # Web browsing / links.
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/chrome" = [ "firefox.desktop" ];
          "text/html" = [ "firefox.desktop" ];
          "application/xhtml+xml" = [ "firefox.desktop" ];

          # Local .htm/.html/.shtml/.xht/.xhtml files, whose type resolves by
          # extension rather than by content sniffing.
          "application/x-extension-htm" = [ "firefox.desktop" ];
          "application/x-extension-html" = [ "firefox.desktop" ];
          "application/x-extension-shtml" = [ "firefox.desktop" ];
          "application/x-extension-xht" = [ "firefox.desktop" ];
          "application/x-extension-xhtml" = [ "firefox.desktop" ];

          # `claude` CLI login callback — keep it, or browser sign-in breaks.
          "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];

          # MATLAB's "open in installed MATLAB" links (written by the MATLAB
          # installer into ~/.local/share/applications/mimeapps.list, which
          # Home Manager now owns — so they have to be declared here).
          "x-scheme-handler/mw-matlab" = [ "mw-matlab.desktop" ];
          "x-scheme-handler/mw-simulink" = [ "mw-simulink.desktop" ];
          "x-scheme-handler/mw-matlabconnector" = [ "mw-matlabconnector.desktop" ];
        };
      };
    };
}
