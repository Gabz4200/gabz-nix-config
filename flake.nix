{
  description = "Gabz NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://install.determinate.systems"
      "https://nix-gaming.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };

  inputs = {
    # Nix ecosystem
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    systems.url = "github:nix-systems/default-linux";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    hardware.url = "github:nixos/nixos-hardware";
    nix-colors.url = "github:misterio77/nix-colors";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      # https://github.com/nix-community/impermanence/pull/272#discussion_r2230796215
      url = "github:misterio77/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gl = {
      url = "github:nix-community/nixgl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:misterio77/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Third party programs, packaged with nix
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming = {
      # url = "github:fufexan/nix-gaming";
      url = "github:misterio77/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # My own programs, packaged with nix
    themes = {
      url = "github:misterio77/themes";
      inputs.systems.follows = "systems";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    systems,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs (import systems) (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );
  in {
    inherit lib;
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    overlays = import ./overlays {inherit inputs outputs;};
    hydraJobs = import ./hydra.nix {inherit inputs outputs;};

    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    nixosConfigurations = {
      # Main desktop
      odin = lib.nixosSystem {
        modules = [
          inputs.determinate.nixosModules.default
          ./hosts/odin
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };
      # Personal laptop (Asus Vivobook)
      hermes = lib.nixosSystem {
        modules = [
          inputs.determinate.nixosModules.default
          ./hosts/hermes
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };
    };

    # Standalone HM only
    homeConfigurations = {
      # Personal laptop
      "gabz@hermes" = lib.homeManagerConfiguration {
        modules = [
          ./home/gabz/hermes.nix 
          ./home/gabz/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
    };
  };
}
