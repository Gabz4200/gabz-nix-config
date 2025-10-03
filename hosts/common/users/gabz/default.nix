{
  pkgs,
  config,
  lib,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = true;
  users.users.gabz = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ifTheyExist [
      "audio"
      "deluge"
      "docker"
      "git"
      "i2c"
      "libvirtd"
      "incus"
      "incus-admin"
      "minecraft"
      "mysql"
      "network"
      "plugdev"
      "podman"
      "realtime"
      "tss"
      "video"
      "wheel"
      "wireshark"
      "networkmanager"
    ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/gabz/ssh.pub);
    #todo: hashedPasswordFile = config.sops.secrets.gabz-password.path;
    packages = with pkgs; [
      kdePackages.kate
      vscode.fhs
      nixd
      alejandra
      uv
      nodejs
      python3
      cachix
      home-manager
      git
      chromium
      firefox-bin
    ];
  };

  sops.secrets.gabz-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  home-manager.users.gabz = import ../../../../home/gabz/${config.networking.hostName}.nix;

  security.pam.services = {
    swaylock = {};
    hyprlock = {};
  };
}
