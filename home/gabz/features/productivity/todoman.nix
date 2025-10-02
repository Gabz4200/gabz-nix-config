{
  config,
  lib,
  ...
}: let
  tasksDir = "${config.home.homeDirectory}/Tasks";
in {
  programs.todoman = {
    enable = true;
    glob = "*/*";
    extraConfig = ''
      path = "${tasksDir}"
      default_list = "inbox"
      date_format = "%d/%m/%Y"
      time_format = "%H:%M"
      humanize = True
      default_due = 0
    '';
  };

  home.persistence."/persist".directories = lib.mkAfter ["Tasks"];

  accounts.calendar = {
    basePath = "Tasks";
    accounts.local = {
      primary = true;
      primaryCollection = "inbox";
      local = {
        type = "filesystem";
        path = tasksDir;
        fileExt = ".ics";
      };
      khal.enable = false;
      vdirsyncer.enable = false;
    };
  };

  programs.fish.interactiveShellInit =
    /*
    fish
    */
    ''
      complete -xc todo -a '(__fish_complete_bash)'
    '';
}
