{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.common-pc-laptop-ssd
    inputs.hardware.nixosModules.common-pc-laptop
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-gpu-intel
    inputs.hardware.nixosModules.common-hidpi
    inputs.hardware.nixosModules.asus-battery

    inputs.home-manager.nixosModules.home-manager

    ./hardware-configuration.nix

    ../common/global
    ../common/users/gabz

    ../common/optional/regreet.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
  ];

  networking = {
    hostName = "hermes";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
    wireless.enable = false;
    nameservers = ["1.1.1.1" "1.0.0.1"];
    useDHCP = false;
  };

  services.resolved = {
    enable = true;
    fallbackDns = ["9.9.9.9" "149.112.112.112"];
    dnssec = "allow-downgrade";
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # GPU
  boot.kernelParams = [
    "i915.enable_guc=2"
    "i915.enable_fbc=1"
    "i915.enable_psr=2"

    # Internet broke without
    "pcie_aspm=off"
  ];

  hardware.intelgpu = {
    computeRuntime = "legacy";
    vaapiDriver = "intel-media-driver";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  # todo: Change to enable Xwayland
  services.xserver.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    neovim
    brightnessctl
  ];

  # Fix Internet Driver
  boot.kernelModules = ["8821ce"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    rtl8821ce
  ];

  # Better for old hardware
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllHardware = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
    ];
  };

  # Home Manager

  # Optionally, use home-manager.extraSpecialArgs to pass arguments to home.nix

  powerManagement.powertop.enable = true;
  programs = {
    light.enable = true;
    adb.enable = true;
    dconf.enable = true;
  };

  # Lid settings
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  hardware.graphics.enable = true;
  home-manager.extraSpecialArgs.hmUseGlobalPkgs = true;
  home-manager.users.gabz.imports = [
    ../../home/gabz/hermes.nix
    ../../home/gabz/nixpkgs.nix
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  system.stateVersion = lib.mkForce "25.05";
}
