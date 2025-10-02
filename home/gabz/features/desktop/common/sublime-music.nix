{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.supersonic];
  home.persistence = {
    "/persist".directories = [".config/supersonic"];
  };
}
