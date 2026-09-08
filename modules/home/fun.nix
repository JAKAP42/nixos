# Toys and terminal eye-candy. Nothing else in the config depends on anything
# here, so this is the one file where appending whatever you feel like is the
# intended workflow -- removing any of it can't break the desktop.
{
  flake.homeModules.fun =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        cowsay
        (fortune.override { withOffensive = true; }) # withOffensive enables the -o flag
        fastfetch # system info screenshot tool (neofetch replacement)

        (ninvaders.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace view.c \
              --replace-fail "start_color();" "start_color(); use_default_colors();" \
              --replace-fail "COLOR_BLACK" "-1"
          '';
        }))
        toipe # typing test
        lolcat
        cmatrix
        (symlinkJoin {
          name = "asciiquarium-transparent-wrapped";
          paths = [ asciiquarium-transparent ];
          nativeBuildInputs = [ makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/asciiquarium --add-flags -t
          '';
        })
        cbonsai
        figlet
        sl
      ];
    };
}
