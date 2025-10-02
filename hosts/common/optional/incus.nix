{
  lib,
  pkgs,
  ...
}: let
  bridgeName = "incusbr0";
in {
  virtualisation.incus = {
    enable = true;
    package = pkgs.incus-lts;
    clientPackage = pkgs.incus-lts;
    socketActivation = true;
    preseed = {
      networks = [
        {
          name = bridgeName;
          type = "bridge";
          config = {
            "ipv4.address" = lib.mkDefault "10.0.100.1/24";
            "ipv4.nat" = "true";
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "dir";
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              name = "eth0";
              network = bridgeName;
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
        }
      ];
    };
  };

  networking.nftables.enable = lib.mkDefault true;
  networking.firewall.trustedInterfaces = lib.mkAfter [bridgeName];
}
