# Copilot Instructions for NixConf

## 🗺️ Architecture essentials

- Flake drives NixOS + Home Manager for hosts `hermes`, `odin`, and the standalone profile `gabz@hermes`.
- `flake.nix` wires inputs (home-manager, impermanence, sops-nix, nix-gl, nix-colors, nix-gaming, determinate) and exports lib, overlays, packages, and dev shells.
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
- Exercise packages with `nix build .#packages.$SYSTEM.<name>` before wiring them into hosts.
- Finish every task by running `alejandra .` and `nix flake check`; don’t commit until both succeed.

## 🔐 Persistence, secrets, graphics

- `/persist` comes from `hosts/common/global/optin-persistence.nix`; list retained paths under `home.persistence` or `environment.persistence`.
- Manage secrets with `sops hosts/common/secrets.yaml` inside the dev shell; `hosts/common/global/sops.nix` wires age recipients and `users/gabz` consumes `gabz-password`.
- Graphics wrappers rely on `inputs.nix-gl`; `home/gabz/hermes.nix` shows nixGL-wrapped Hyprland/Vulkan and generic Linux target support.

## 🧭 Tooling extras

- Language templates (e.g., `templates/python/`) mirror overlay expectations; copy them when adding starters.
- Desktop bindings live in `home/gabz/features/desktop/**`; keep brightness/audio shortcuts aligned with swayosd + brightnessctl helpers.
- MCP helpers: `#codebase` for cross-repo search, `#mcp_oraios_serena_get_symbols_overview` for symbol maps, `#mcp_oraios_serena_read_memory` for stored guidance, `#mcp_oraios_serena_onboarding` if metadata drifts.
- Pull upstream option docs via `#mcp_upstash_conte_get-library-docs` or `#mcp_nixos_nixos_search`, reconciling results with local overrides before editing modules.

## 🧰 Tool reference

- **VS Code built-ins**: `changes` (diffs), `edit` (apply edits), `extensions` (marketplace search), `fetch` (web capture), `githubRepo` (search remote repos), `new` & `newWorkspace` (scaffold VS Code project tasks), `getProjectSetupInfo` (suggest tasks.json entries), `installExtension`, `runVscodeCommand`, `openSimpleBrowser`, `problems`, `runCommands`, `runNotebooks`, `runTasks`, `search`, `testFailure`, `think`, `todos`, `usages`, `vscodeAPI`.
- **Misterio77/nix-config docs**: `fetch_generic_url_content`, `fetch_nix_config_documentation`, `search_nix_config_code`, `search_nix_config_documentation` for upstream template insight.
- **CognitionAI DeepWiki**: `ask_question`, `read_wiki_contents`, `read_wiki_structure` to mine external GitHub wikis referenced by overlays or modules.
- **NixOS option suite**: `home_manager_info`, `home_manager_list_options`, `home_manager_options_by_prefix`, `home_manager_search`, `home_manager_stats`, `nixhub_find_version`, `nixhub_package_versions`, `nixos_channels`, `nixos_flakes_search`, `nixos_flakes_stats`, `nixos_info`, `nixos_search`, `nixos_stats` when auditing options or package availability.
- **Serena workspace tools**: `activate_project`, `check_onboarding_performed`, `delete_memory`, `find_file`, `find_referencing_symbols`, `find_symbol`, `get_current_config`, `get_symbols_overview`, `insert_after_symbol`, `insert_before_symbol`, `list_dir`, `list_memories`, `onboarding`, `read_memory`, `replace_symbol_body`, `search_for_pattern`, `think_about_collected_information`, `think_about_task_adherence`, `think_about_whether_you_are_done`, `write_memory` for repo-aware navigation and reflection.
- **Upstash Context7**: `resolve-library-id`, `get-library-docs` to fetch authoritative library documentation before modifying integrations.

## ✅ Finish strong

- Review git diff, ensure only intentional changes remain, and stage before committing.
- For host/profile edits, optionally dry-run `nixos-rebuild --flake .#<host> build` or `home-manager --flake .#gabz@hermes build` to catch evaluation surprises early.

ALWAYS use `read_memory` from serena to read all memories in the start of any new main task on the sessions.
