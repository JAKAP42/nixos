# The login greeter, made to look like hyprlock.
#
# SDDM is the only piece of KDE still in the daily path: it is what asks for the
# password before Hyprland starts. Stock Breeze looks nothing like the lock
# screen you see for the rest of the session, so this replaces it with a theme
# that reproduces hyprlock's layout and Stylix colours, over a wallpaper drawn
# at random from the same folder waypaper uses.
#
# Two halves:
#   1. a QML theme package (below) installed into the system profile, which SDDM
#      finds via /run/current-system/sw/share/sddm/themes;
#   2. a oneshot unit that runs before the greeter, picks a random image from the
#      waypaper folder and copies it somewhere the (unprivileged) sddm user can
#      actually read.
#
# To check a change without rebooting, run `sddm --test-mode` (the daemon) and
# look at it. Running `sddm-greeter-qt6 --test-mode --theme ...` renders the QML
# too, but it skips the daemon's theme/greeter selection -- so it happily shows
# a theme that the real greeter would reject and silently replace with the
# fallback. Ask the daemon, not the greeter.
{
  flake.nixosModules.sddm =
    {
      pkgs,
      lib,
      config,
      userconf,
      ...
    }:
    let
      c = config.lib.stylix.colors.withHashtag;

      # Same colour roles Stylix hands hyprlock: inner/outer/font plus the
      # checking and failure tints. Keeping the mapping here (rather than raw
      # hex) means a base16Scheme swap in stylix.nix moves the greeter too.
      inner = c.base00;
      outer = c.base03;
      fontColor = c.base05;
      checkColor = c.base0A;
      failColor = c.base08;
      fontFamily = config.stylix.fonts.monospace.name;

      # $HOME is mode 0700, so sddm cannot read the wallpaper folder directly.
      # The pre-start unit copies one image here instead. No extension: Qt falls
      # back to content sniffing when the suffix tells it nothing.
      wallpaper = "/var/lib/sddm-wallpaper/current";

      mainQml = pkgs.writeText "Main.qml" ''
        import QtQuick 2.15

        Rectangle {
            id: root
            color: "${inner}"

            // hyprlock draws its input field in logical pixels, which this
            // 1920x1080 panel then scales by 1.5. SDDM runs unscaled, so derive
            // the same factor from the screen instead of hardcoding it: 1080/720
            // is 1.5 here, and a 1440p panel lands on 2.0.
            property real uiScale: Math.min(3.0, Math.max(1.0, height / 720))

            property color innerColor: "${inner}"
            property color outerColor: "${outer}"
            property color fontColor:  "${fontColor}"
            property color checkColor: "${checkColor}"
            property color failColor:  "${failColor}"

            // sddm remembers the last account; fall back to the only one on the
            // machine if it has nothing stored yet (first boot after install).
            property string loginUser: (typeof userModel !== "undefined" && userModel.lastUser)
                                       ? userModel.lastUser : "${userconf.username}"
            property int sessionIndex: sessionModel.lastIndex
            property bool busy: false
            property int attempts: 0
            property string message: "Input Password..."

            Image {
                anchors.fill: parent
                source: "file://${wallpaper}"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            function tryLogin() {
                if (password.text.length === 0)
                    return;
                root.busy = true;
                field.border.color = root.checkColor;
                sddm.login(root.loginUser, password.text, root.sessionIndex);
            }

            Connections {
                target: sddm
                function onLoginFailed() {
                    root.busy = false;
                    root.attempts += 1;
                    root.message = "Authentication failed (" + root.attempts + ")";
                    field.border.color = root.failColor;
                    password.text = "";
                    password.forceActiveFocus();
                }
            }

            // The input field: hyprlock's default 200x50 pill, 3px outline,
            // centred with a 20px downward nudge, faded while empty.
            Rectangle {
                id: field
                width: 200 * root.uiScale
                height: 50 * root.uiScale
                radius: height / 2
                color: root.innerColor
                border.width: Math.round(3 * root.uiScale)
                border.color: root.outerColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 20 * root.uiScale

                opacity: (password.text.length === 0 && !root.busy) ? 0.75 : 1.0

                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: parent.radius
                    anchors.rightMargin: parent.radius
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    passwordMaskDelay: 0
                    color: root.fontColor
                    font.family: "${fontFamily}"
                    font.pixelSize: 16 * root.uiScale
                    clip: true
                    focus: true
                    enabled: !root.busy
                    onAccepted: root.tryLogin()
                    onTextChanged: {
                        if (!root.busy) {
                            field.border.color = root.outerColor;
                            root.message = "Input Password...";
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: password.text.length === 0
                    text: root.message
                    color: root.fontColor
                    opacity: 0.7
                    font.family: "${fontFamily}"
                    font.italic: true
                    font.pixelSize: 15 * root.uiScale
                }
            }

            // Everything below is what a greeter needs and a lock screen does
            // not: which session to start, and the power actions. Kept at the
            // edges so the centre still reads as hyprlock, and sat on the same
            // translucent base00 the input field uses -- plain text vanished
            // against bright wallpapers.
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 36 * root.uiScale
                width: sessions.width + 28 * root.uiScale
                height: sessions.height + 14 * root.uiScale
                radius: height / 2
                color: root.innerColor
                opacity: 0.72

                Row {
                    id: sessions
                    anchors.centerIn: parent
                    spacing: 22 * root.uiScale

                    Repeater {
                        model: sessionModel
                        delegate: Text {
                            text: model.name ? model.name : ""
                            color: index === root.sessionIndex ? root.fontColor : "${c.base04}"
                            opacity: index === root.sessionIndex ? 1.0 : 0.65
                            font.family: "${fontFamily}"
                            font.pixelSize: 13 * root.uiScale
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.sessionIndex = index;
                                    password.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 36 * root.uiScale
                width: power.width + 28 * root.uiScale
                height: power.height + 14 * root.uiScale
                radius: height / 2
                color: root.innerColor
                opacity: 0.72
                visible: power.width > 0

                Row {
                    id: power
                    anchors.centerIn: parent
                    spacing: 18 * root.uiScale

                    Text {
                        visible: sddm.canSuspend
                        text: "suspend"
                        color: "${c.base04}"
                        font.family: "${fontFamily}"
                        font.pixelSize: 13 * root.uiScale
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sddm.suspend()
                        }
                    }
                    Text {
                        visible: sddm.canReboot
                        text: "restart"
                        color: "${c.base04}"
                        font.family: "${fontFamily}"
                        font.pixelSize: 13 * root.uiScale
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sddm.reboot()
                        }
                    }
                    Text {
                        visible: sddm.canPowerOff
                        text: "shutdown"
                        color: root.failColor
                        font.family: "${fontFamily}"
                        font.pixelSize: 13 * root.uiScale
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sddm.powerOff()
                        }
                    }
                }
            }

            Component.onCompleted: password.forceActiveFocus()
        }
      '';

      # QtVersion=6 is not optional: sddm 0.21 ships both a Qt5 and a Qt6
      # greeter and reads that key to decide which binary to launch. Leave it
      # out and it goes looking for the Qt5 `sddm-greeter`, which this nixpkgs
      # sddm does not build -- it then logs "requires missing ... using fallback
      # theme" and quietly shows the stock greeter instead of this one.
      metadata = pkgs.writeText "metadata.desktop" ''
        [SddmGreeterTheme]
        Name=hyprlock
        Description=hyprlock-style greeter themed by Stylix
        Author=nixos config
        Type=sddm-theme
        Version=1.0
        License=MIT
        MainScript=Main.qml
        Theme-Id=hyprlock
        QtVersion=6
      '';

      theme = pkgs.runCommand "sddm-theme-hyprlock" { } ''
        d=$out/share/sddm/themes/hyprlock
        mkdir -p $d
        cp ${mainQml} $d/Main.qml
        cp ${metadata} $d/metadata.desktop
      '';
    in
    {
      # SDDM looks themes up in /run/current-system/sw/share/sddm/themes, which
      # is exactly what installing the package system-wide gives us.
      environment.systemPackages = [ theme ];
      services.displayManager.sddm.theme = "hyprlock";

      # Pick the greeter's background before the greeter starts. Runs as root so
      # it can read inside the user's home; the copy it leaves behind is
      # world-readable, which is all the sddm user needs.
      #
      # A new image is chosen every time display-manager is (re)started -- so at
      # each boot, or on demand with `systemctl restart display-manager`.
      systemd.services.sddm-wallpaper = {
        description = "Pick a random SDDM background from the waypaper folder";
        before = [ "display-manager.service" ];
        wantedBy = [ "display-manager.service" ];
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "sddm-wallpaper";
          StateDirectoryMode = "0755";
        };
        path = with pkgs; [
          coreutils
          findutils
          gnused
        ];
        script = ''
          home=${lib.escapeShellArg config.users.users.${userconf.username}.home}

          # Same folder waypaper paints the desktop from, read out of its config
          # so changing it in the GUI moves the greeter too.
          folder=$(sed -n 's/^folder *= *//p' "$home/.config/waypaper/config.ini" \
                   2>/dev/null | head -n1)
          folder=''${folder/#\~/$home}
          [ -n "$folder" ] || folder="$home/Pictures/wallpapers"

          img=$(find -L "$folder" -maxdepth 1 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
                -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.bmp' \) \
                2>/dev/null | shuf -n1)

          # No images (or no folder yet): leave whatever is already there. The
          # theme falls back to a flat base00 background if the file is missing,
          # so login still works either way.
          [ -n "$img" ] || exit 0

          install -m 0644 "$img" ${wallpaper}.new
          mv ${wallpaper}.new ${wallpaper}
        '';
      };
    };
}
