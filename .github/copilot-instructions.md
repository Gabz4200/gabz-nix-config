# Copilot Instructions for NixConf

## 🗺️ Architecture essentials

- Flake drives NixOS + Home Manager for hosts `hermes`, `odin`, and the standalone profile `gabz@hermes`.
- `flake.nix` wires inputs (home-manager, impermanence, sops-nix, nix-gl, nix-colors, nix-gaming, determinate) and exports lib, overlays, packages, dev shells, and Hydra jobs.
- Host modules under `hosts/<name>/` import shared globals, optional capabilities, then host overrides alongside hardware data.
- Shared logic in `hosts/common/global` auto-imports `modules/nixos/default.nix`, enabling impermanence, tailscale, nix-ld, upgrades, and display/power tweaks everywhere.
- `hosts/common/users/gabz` provisions the primary user, sourcing keys from `home/gabz/ssh.pub` and secrets from `hosts/common/secrets.yaml`.
- `home/gabz/<target>.nix` imports `home/gabz/global` for impermanence defaults, helper scripts, and automatic Home Manager module wiring.

## 🧩 Modules & features

- Modules follow `{ inputs, outputs, lib, pkgs, ... }:` and extend `imports`; rely on `outputs.nixosModules`/`outputs.homeManagerModules` rather than rebuilding lists.
- Feature flags live in `home/gabz/features/**`; compose them to assemble desktops (Hyprland expects mako, playerctld, pass-wofi siblings).
- `modules/home-manager/default.nix` exports reusable HM modules (monitors, wallpaper, pass-secret-service) that `home/gabz/global` auto-imports.
- `overlays/default.nix` exposes flake inputs under `pkgs.inputs.*`, registers `pkgs/*` packages, and patches upstream apps (qutebrowser, wl-clipboard, todoman, gamescope).
- Shell-script packages live under `pkgs/pass-wofi`; Python packaging uses `pkgs/lyrics` with `python3Packages.callPackage` and co-located patches.

## 🚀 Daily workflows

- Enter the dev shell with `nix develop` (legacy-compatible `nix-shell`).
- Run VS Code “NixOS MCP: Refresh” before and after editing `.nix` files so symbol metadata stays current.
- Build systems locally via `nixos-rebuild --flake .#hermes switch`; `./deploy.sh hermes[,odin]` wraps remote rebuilds with SSH control reuse.
- Apply user profiles using `home-manager --flake .#gabz@hermes switch`.
- Exercise packages with `nix build .#packages.$SYSTEM.<name>` before wiring them into hosts or Hydra.
- Finish every task by running `alejandra .` and `nix flake check`; don’t commit until both succeed.

## 🔐 Persistence, secrets, graphics

- `/persist` comes from `hosts/common/global/optin-persistence.nix`; list retained paths under `home.persistence` or `environment.persistence`.
- Manage secrets with `sops hosts/common/secrets.yaml` inside the dev shell; `hosts/common/global/sops.nix` wires age recipients and `users/gabz` consumes `gabz-password`.
- Graphics wrappers rely on `inputs.nix-gl`; `home/gabz/hermes.nix` shows nixGL-wrapped Hyprland/Vulkan and generic Linux target support.

## 🧭 Tooling extras

- Hydra jobs in `hydra.nix` publish redistributable packages plus nixos/home configurations.
- Language templates (e.g., `templates/python/`) mirror overlay expectations; copy them when adding starters.
- Desktop bindings live in `home/gabz/features/desktop/**`; keep brightness/audio shortcuts aligned with swayosd + brightnessctl helpers.
- MCP helpers: `#codebase` for cross-repo search, `#mcp_oraios_serena_get_symbols_overview` for symbol maps, `#mcp_oraios_serena_read_memory` for stored guidance, `#mcp_oraios_serena_onboarding` if metadata drifts.
- Pull upstream option docs via `#mcp_upstash_conte_get-library-docs` or `#mcp_nixos_nixos_search`, reconciling results with local overrides before editing modules.

## ✅ Finish strong

- Review git diff, ensure only intentional changes remain, and stage before committing.
- For host/profile edits, optionally dry-run `nixos-rebuild --flake .#<host> build` or `home-manager --flake .#gabz@hermes build` to catch evaluation surprises early.
