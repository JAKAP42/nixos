# The user account, plus the Home Manager wiring. Home Manager runs as a NixOS
# module here (not standalone), and the user's dotfiles are assembled from the
# `flake.homeModules.*` collected across modules/home/.
{ self, inputs, ... }:
{
  flake.nixosModules.user =
    { pkgs, userconf, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      # Define a user account. Don't forget to set a password with 'passwd'.
      users.users.${userconf.username} = {
        isNormalUser = true;
        description = userconf.displayname;
        extraGroups = [ "networkmanager" "wheel" ];
        packages = with pkgs; [
          kdePackages.kate
        ];
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        # If HM would overwrite an existing dotfile, back it up instead of failing.
        backupFileExtension = "hm-bak";
        # Make userconf available inside home-manager modules too.
        extraSpecialArgs = { inherit userconf; };
        # Assemble the user's config from all the home modules in the tree.
        users.${userconf.username}.imports = with self.homeModules; [
          core
          hyprland
          waybar
          rofi
          kitty
          mako
          lock
          wallpaper
          packages
          nwgDrawer
          vscodium
          onenote
          onedrive
          mega
        ];
      };
    };
}
