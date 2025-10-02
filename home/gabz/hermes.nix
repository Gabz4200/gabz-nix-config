{pkgs, inputs, ...}: {
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
    pkgs.lxd-lts
  ];

  targets.genericLinux.enable = true;
  nixGL = {
    packages = inputs.nix-gl.packages;
    defaultWrapper = "mesa";
    installScripts = ["mesa"];
    vulkan.enable = true;
  };

  monitors = [
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
