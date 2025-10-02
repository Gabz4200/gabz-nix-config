{
  config,
  lib,
  ...
}: let
  remoteId = "EIDJBPY-QXNRYHF-HC6Q4ER-O5FVG5A-2BZNK4F-Q6DDQC6-744RYJU-4DHZTQR";
  syncDir = "${config.home.homeDirectory}/Sync";
in {
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "celular" = {
          id = remoteId;
          name = "celular";
          addresses = ["dynamic"];
          autoAcceptFolders = true;
        };
      };
      folders = {
        default = {
          id = "default";
          label = "Sync";
          path = syncDir;
          type = "sendreceive";
          devices = ["celular"];
        };
      };
    };
  };

  home.persistence."/persist".directories = lib.mkAfter ["Sync"];
}
