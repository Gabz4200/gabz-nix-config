# Suggested Commands
- `nix develop` (or `nix-shell`) – enter the repo dev shell with `nix`, `home-manager`, `sops`, and signing tools.
- `nixos-rebuild --flake .#hermes switch` / `--flake .#odin switch` – build and apply local NixOS configurations.
- `./deploy.sh hermes[,odin]` – trigger remote rebuilds via SSH with reuse of control masters.
- `home-manager --flake .#gabz@hermes switch` – activate the standalone Home Manager profile.
- `nix build .#packages.$SYSTEM.<name>` – build custom packages from `pkgs/` (e.g., `pass-wofi`).
- `sops hosts/common/secrets.yaml` – edit encrypted secrets with age recipients preconfigured by `hosts/common/global/sops.nix`.
- `alejandra .` – format all Nix files (also run after substantive edits).
- `nix flake check` – evaluate the flake to catch module or package errors before committing.
- VS Code Command Palette → `NixOS MCP: Refresh` – run before and after changing any `.nix` file to rebuild the module graph metadata.