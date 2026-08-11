{
  flake.homeModules.kitty =
    { lib, ... }:
    {
      # Kitty gets its colors + font from Stylix (catppuccin-mocha / JetBrainsMono).
      # This module only adds the "look": a translucent dark background that lets
      # the wallpaper show through faintly, roomy padding, and minimal framing.

      # Transparency goes through Stylix's own knob (0 = fully see-through,
      # 1 = solid) so it doesn't clash with the config Stylix generates.
      stylix.opacity.terminal = 0.85;

      programs.kitty = {
        enable = true;
        settings = {
          # Breathing room between the text and the window edge.
          window_padding_width = 12;
          # Hyprland draws the window border and gaps, so kitty needs no title
          # bar of its own.
          hide_window_decorations = true;

          # Cursor.
          cursor_shape = "beam";
          cursor_shape_unfocused = "unchanged";
          cursor_blink_interval = 1;
          cursor_stop_blinking_after = 15;
          cursor_trail = 1;
    

          # Generous scrollback; silence the audio bell.
          scrollback_lines = 10000;
          enable_audio_bell = false;
          # Keep the scrollbar handle always visible (default "scrolled" only
          # flashes it while scrolling back). Options: always, scrolled, hovered,
          # scrolled-and-hovered, never.
          scrollbar = "always";
          # Tidy tab bar if you ever open tabs inside one window.
          tab_bar_edge = "bottom";
          tab_bar_style = "powerline";
        };

        # Stylix paints the background via an `include <theme>` line that it appends
        # to the end of the config, and that theme sets catppuccin's navy base00.
        # `mkAfter` forces this line to land *after* that include so it wins, giving
        # a neutral black background that matches the waybar pills. (Text/syntax
        # colors still come from the Stylix theme above.)
        extraConfig = lib.mkAfter ''
          background #000000
        '';
      };
    };
}
