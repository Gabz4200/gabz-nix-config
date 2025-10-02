{
  pkgs,
  inputs,
  lib,
  ...
}: let
  nixglPkgs = pkgs.extend inputs.nix-gl.overlay;
  nixglAuto = nixglPkgs.nixgl.auto;
in {
  imports = [
    ./global
    ./features/desktop/hyprland
    ./features/desktop/wireless
    ./features/productivity
    ./features/pass
    ./features/games
  ];

  # Purple
  wallpaper = pkgs.inputs.themes.wallpapers.deer-lunar-fantasy;

  home.username = "gabz";
  home.packages = [
    pkgs.juju
    pkgs.sshuttle
    pkgs.incus-lts
  ];

  targets.genericLinux.enable = true;
  nixGL = {
    packages =
      nixglAuto
      // {
        default = nixglAuto.nixGLDefault;
        nixGLDefault = nixglAuto.nixGLDefault;
        nixGLIntel = nixglPkgs.nixgl.nixGLIntel;
        nixVulkanIntel = nixglPkgs.nixgl.nixVulkanIntel;
        # Add nixGLNvidia wrappers here if dedicated GPUs return.
      };
    defaultWrapper = "mesa";
    installScripts = ["mesa"];
    vulkan.enable = true;
  };

  monitors = lib.mkForce [
    {
      name = "eDP-1";
      width = 1920;
      height = 1080;
      workspace = "1";
      primary = true;
      refreshRate = 60;
      scale = "1";
    }
  ];
}
