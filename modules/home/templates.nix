# Dolphin's "Create New >" submenu, extended with office documents.
#
# KIO builds that submenu from *.desktop files found in any
# <data dir>/templates/ directory -- so ~/.local/share/templates/. Each entry
# is `Type=Link` pointing at a real document; picking it asks for a file name
# and copies the document there.
#
# Two things about that copy dictate the shape of this module, both verified by
# hand with `kioclient copy`:
#
#   1. KIO copies a symlink *as a symlink*. So the templates cannot be the
#      usual Home Manager store symlinks -- Dolphin would create a link back
#      into /nix/store instead of a new document.
#   2. KIO preserves the source's permissions, and everything in the store is
#      read-only (0444). A document copied straight out of the store would be
#      unwritable, so ONLYOFFICE could not save it.
#
# Hence: the .desktop entries are ordinary Home Manager symlinks (KIO only
# reads those), but the documents they point at are real 0644 copies placed by
# the activation script below.
{
  flake.homeModules.templates =
    { config, pkgs, lib, ... }:
    let
      # ONLYOFFICE already ships blank documents for its own "New document"
      # action, one set per locale, so no template files are stored in this
      # repo and nothing extra is downloaded. They live inside the FHS sandbox
      # rootfs; the outer package is only a wrapper and does not have them.
      #
      # Locale choice: "default" is A4 with en-US proofing, which fits this
      # machine (A4 paper here, en_US.UTF-8 locale from base.nix). "en-US"
      # would give US Letter; "nb-NO" would set the proofing language to
      # Norwegian.
      blanks = "${pkgs.onlyoffice-desktopeditors.fhsenv}/usr/share/desktopeditors/converter/empty/default";

      # Hidden from Dolphin's own view of the templates folder, which is the
      # convention KDE's shipped templates use for their payload files.
      sourceDir = "${config.xdg.dataHome}/templates/.source";

      # `label` is what the menu shows; KIO strips the trailing "..." (which
      # signals "this opens a dialog") before using it as the default filename.
      entries = [
        {
          ext = "docx";
          label = "Word Document";
          comment = "Empty text document (ONLYOFFICE / Word)";
          icon = "x-office-document";
        }
        {
          ext = "xlsx";
          label = "Excel Spreadsheet";
          comment = "Empty spreadsheet (ONLYOFFICE / Excel)";
          icon = "x-office-spreadsheet";
        }
        {
          ext = "pptx";
          label = "PowerPoint Presentation";
          comment = "Empty presentation (ONLYOFFICE / PowerPoint)";
          icon = "x-office-presentation";
        }
      ];
    in
    {
      # URL is absolute rather than the relative ".source/new.docx" KDE's own
      # templates use, so it does not depend on how KIO resolves relative
      # template paths.
      xdg.dataFile = lib.listToAttrs (
        map (
          e:
          lib.nameValuePair "templates/office-${e.ext}.desktop" {
            text = ''
              [Desktop Entry]
              Type=Link
              Name=${e.label}...
              Comment=${e.comment}
              Icon=${e.icon}
              URL=${sourceDir}/new.${e.ext}
            '';
          }
        ) entries
      );

      # `install` dereferences the store symlinks in the FHS rootfs and sets a
      # writable mode, which is the whole point (see the header comment). It
      # rewrites the copies on every activation, so changing `blanks` above
      # takes effect on the next rebuild.
      home.activation.officeTemplates = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p ${lib.escapeShellArg sourceDir}
        ${lib.concatMapStrings (e: ''
          $DRY_RUN_CMD install -m 644 ${lib.escapeShellArg "${blanks}/new.${e.ext}"} ${lib.escapeShellArg "${sourceDir}/new.${e.ext}"}
        '') entries}
      '';
    };
}
