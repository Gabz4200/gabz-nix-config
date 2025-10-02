# MCP Tools Guide

## Workspace bootstrap

- `#mcp_oraios_serena_activate_project` – set the active Serena project; run once per VS Code session so symbol-aware tools resolve inside `/home/gabz/NixConf`.
- `#mcp_oraios_serena_onboarding` – displays the onboarding checklist and reminders; re-run if you need to revisit starter guidance.
- `#mcp_oraios_serena_check_onboarding_performed` – confirm whether onboarding memories were populated; reports available memory files.
- `#mcp_oraios_serena_write_memory` / `#mcp_oraios_serena_read_memory` / `#mcp_oraios_serena_list_memories` / `#mcp_oraios_serena_delete_memory` – manage Serena knowledge notes (project overview, style, commands). Use write/read to persist and retrieve repo-specific instructions.

## Code navigation & editing

- `#mcp_oraios_serena_get_symbols_overview` – list top-level symbols for a file; ideal before editing complex modules such as `hosts/common/global/default.nix` or Hyprland features.
- `#mcp_oraios_serena_find_symbol` – fetch symbol definitions (optionally with bodies) for targeted inspection or edits.
- `#mcp_oraios_serena_find_referencing_symbols` – locate call sites/usages when refactoring modules or packages.
- `#mcp_oraios_serena_insert_before_symbol` / `#mcp_oraios_serena_insert_after_symbol` / `#mcp_oraios_serena_replace_symbol_body` – structured editors for adding imports, appending module content, or rewriting functions without manual diffing.
- `#mcp_oraios_serena_search_for_pattern` – regex/substring search across the repo; helpful for cross-cutting patterns inside `hosts/**`, `modules/**`, or `pkgs/**`.
- `#mcp_oraios_serena_find_file` / `#mcp_oraios_serena_list_dir` – lightweight filesystem queries when locating modules or feature folders.

## Project context & status

- `#mcp_oraios_serena_get_current_config` – display Serena runtime info, active project, and available tools.
- `#mcp_oraios_serena_think_about_task_adherence`, `#mcp_oraios_serena_think_about_collected_information`, `#mcp_oraios_serena_think_about_whether_you_are_done`, and `#think` – reflection helpers to ensure plans cover all requirements and to review collected context before finishing a task.
- `#mcp_oraios_serena_onboarding` (repeatable) – revisit onboarding instructions if new contributors join.

## External insight & documentation

- `#codebase` – semantic search for patterns that span hosts, home modules, overlays, and packages.
- `#fetch_webpage` / `#mcp_misterio77_ni_fetch_generic_url_content` – pull upstream docs or blog posts referenced in configuration comments and module notes.
- `#Misterio77/nix-config nix-config template Docs` – access rationale from the upstream template; reconcile findings with this fork’s overrides.
- `#mcp_cognitionai_d_ask_question` – query external GitHub repositories when you need insight on upstream packages patched via `overlays/default.nix`.
- `#mcp_upstash_conte_get-library-docs` – fetch current docs for third-party software (Hyprland, sops, etc.) when adjusting feature modules.

## NixOS & Home Manager option discovery

- `#mcp_nixos_nixos_search`, `#mcp_nixos_nixos_info`, `#mcp_nixos_nixos_channels`, `#mcp_nixos_nixos_stats`, `#mcp_nixos_nixos_flakes_search`, `#mcp_nixos_nixos_flakes_stats` – audit NixOS options, channel health, and prospective flakes before updating `hosts/**` or `flake.nix`.
- `#mcp_nixos_nixhub_find_version` / `#mcp_nixos_nixhub_package_versions` – confirm package availability and versions when maintaining custom derivations under `pkgs/` or overlays.
- `#mcp_nixos_home_manager_search`, `#mcp_nixos_home_manager_options_by_prefix`, `#mcp_nixos_home_manager_list_options`, `#mcp_nixos_home_manager_info`, `#mcp_nixos_home_manager_stats` – explore Home Manager options relevant to `home/gabz/**` modules and feature flags.

These tools complement the local mandates to run the VS Code `NixOS MCP` before/after `.nix` edits, `alejandra .`, and `nix flake check` at the end of every task.
