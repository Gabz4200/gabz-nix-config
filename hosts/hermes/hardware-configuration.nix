{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    ../common/optional/ephemeral-btrfs.nix
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "i686-linux"
  ];
  hardware.cpu.intel.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  networking.useDHCP = lib.mkDefault true;

  boot.resumeDevice = "/dev/mapper/${config.networking.hostName}";
  systemd.settings.Manager.DefaultTimeoutStopSec = "300s";

  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      kernelModules = ["kvm-intel"];
    };
    initrd.systemd.services.wait-for-resume-device = {
      description = "Wait for resume device";
      wantedBy = ["initrd.target"];
      after = ["systemd-udev-settle.service"];
      serviceConfig.Type = "oneshot";
      script = ''
        while [ ! -e ${lib.escapeShellArg config.boot.resumeDevice} ]; do
          sleep 1
        done
      '';
    };
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = true;
    };
  };

  disko.devices.disk.main = let
    inherit (config.networking) hostName;
  in {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        esp = {
          name = "ESP";
          size = "1024M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = hostName;
            settings.allowDiscards = true;
            content = let
              this = config.disko.devices.disk.main.content.partitions.luks.content.content;
            in {
              type = "btrfs";
              extraArgs = ["-L${hostName}"];
              postCreateHook = ''
                MNTPOINT=$(mktemp -d)
                mount -t btrfs "${this.device}" "$MNTPOINT"
                trap 'umount $MNTPOINT; rm -d $MNTPOINT' EXIT
                btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
                btrfs property set -ts "$MNTPOINT/swap" compression none
                chattr +C "$MNTPOINT/swap"
              '';
              subvolumes = {
                "/root" = {
                  mountOptions = ["compress=zstd:12" "ssd"];
                  mountpoint = "/";
                };
                "/nix" = {
                  mountOptions = ["compress=zstd:12" "ssd" "noatime"];
                  mountpoint = "/nix";
                };
                "/persist" = {
                  mountOptions = ["compress=zstd:12" "ssd" "noatime"];
                  mountpoint = "/persist";
                };
                "/swap" = {
                  mountOptions = ["noatime" "nodatacow" "nodatasum"];
                  mountpoint = "/swap";
                  swap.swapfile = {
                    size = "12288M";
                    path = "swapfile";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
  fileSystems."/persist".neededForBoot = true;
}
