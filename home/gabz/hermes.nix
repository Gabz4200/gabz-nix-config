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
    #todo: ./features/games/factorio.nix
    ./features/games/osu.nix
    ./features/games/star-citizen.nix
  ];

  # Purple
  wallpaper = pkgs.inputs.themes.wallpapers.deer-lunar-fantasy;

  home.username = "gabz";
  home.packages = with pkgs; [
    fh

    juju
    sshuttle
    incus-lts

    aider-chat-full
    gemini-cli
    gpt4all
    lmstudio
    #todo: local-ai
    alpaca
    codebuff
    uv
    nodejs
    docker
    inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs
    librechat
    #todo:
    #(python3.withPackages
    #(ps:
    # with ps; [
    #   langchain
    #   langchain-openai
    #   langchain-community
    #   chromadb
    #   sentence-transformers
    #   llama-index
    #   llama-cpp-python
    # ]))
    llama-cpp
  ];

  programs.obsidian.enable = true;

  programs.vscode.enable = true;
  programs.zed-editor.enable = true;

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
