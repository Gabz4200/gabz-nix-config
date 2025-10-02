{
  fonts = import ./fonts.nix;
  monitors = import ./monitors.nix;
  pass-secret-service = import ./pass-secret-service.nix;
  wallpaper = import ./wallpaper.nix;
  colors = import ./colors.nix;
  export-sessions = import ./export-sessions.nix;
}
