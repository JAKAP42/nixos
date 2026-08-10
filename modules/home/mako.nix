{
  flake.homeModules.mako =
    { ... }:
    {
      # Wayland notification daemon. Colors/fonts come from Stylix's mako target.
      services.mako = {
        enable = true;
        settings = {
          default-timeout = 5000;
          border-radius = 8;
          border-size = 2;
          padding = "10";
          width = 350;
          "max-visible" = 5;
        };
      };
    };
}
