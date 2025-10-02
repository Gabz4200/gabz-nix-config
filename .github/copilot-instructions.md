# Copilot Instructions for NixConf

- This repository is a flake-driven NixOS and Home Manager configuration for hosts `odin` and `hermes`, plus the `gabz@hermes` standalone profile.
- Started from [Misterio77/nix-config](https://github.com/Misterio77/nix-config); consult the template docs via the `#Misterio77/nix-config` MCP tools when upstream rationale matters, but prefer the local overrides in this fork.
- `flake.nix` declares upstream inputs (home-manager, impermanence, sops-nix, nix-gl, nix-colors, nix-gaming, determinate) and exports custom `lib`, overlays, packages, dev shells, and Hydra jobs.
- Each host under `hosts/<name>/` imports hardware data, shared modules from `hosts/common/global`, optional features from `hosts/common/optional`, and its own `hardware-configuration.nix`.
- Shared configuration in `hosts/common/global/*.nix` wires impermanence (`optin-persistence.nix`), sops-nix (`sops.nix`), tailscale, auto-upgrades, nix-ld, and display/power tweaks; it automatically imports every module exported from `modules/nixos/default.nix`.
- Optional host capabilities live in `hosts/common/optional/*.nix` (e.g. `secure-boot.nix`, `wireless.nix`, `regreet.nix`) and are pulled into individual hosts as needed.
- `hosts/common/users/gabz` provisions the primary user, reads the SSH key from `home/gabz/ssh.pub`, and attaches secrets defined in `hosts/common/secrets.yaml` via sops.
- User environments live in `home/gabz/<target>.nix`; each imports `home/gabz/global`, which enables impermanence, sets nix defaults, and adds helper scripts like `specialisation` and `toggle-theme`.
- Feature flags are modelled as standalone modules inside `home/gabz/features/**`; for example `home/gabz/features/desktop/hyprland` layers Hyprland configuration, reuses `config.colorscheme`, and expects supporting services (mako, playerctld, pass-wofi) from sibling features.
- Custom Home Manager modules are exported from `modules/home-manager/default.nix` (e.g. `monitors.nix`, `wallpaper.nix`, `pass-secret-service.nix`) and are auto-imported by `home/gabz/global`.
- `modules/nixos/*` provides reusable NixOS components (Hydra auto-upgrade, OpenRGB, steam fixes) that hosts inherit through `outputs.nixosModules`.
- Overlays in `overlays/default.nix` add abbreviated access to flake inputs (`pkgs.inputs.<name>`), register packages from `pkgs/`, extend `pkgs.formats` and `pkgs.vimPlugins`, and patch upstream software (qutebrowser, wl-clipboard, pass, todoman, gamescope).
- Custom derivations live under `pkgs/`; use `pkgs/pass-wofi` for shell-script packages and `pkgs/lyrics` for Python packaging via `python3Packages.callPackage`.
- Whenever you touch a `.nix` file, run the workspace `NixOS MCP` tools (Command Palette → type `NixOS`) before editing to refresh metadata and again after saving to validate the module graph.
- A shared development shell (`nix develop` or `nix-shell`) is defined in `shell.nix`; it exposes `nix`, `home-manager`, `sops`, `ssh-to-age`, `gnupg`, and `age`.
- System builds run with `nixos-rebuild --flake .#hermes switch`; for remote machines use `./deploy.sh hermes[,odin]`, which wraps `nixos-rebuild` with `--target-host` and reuses SSH control masters.
- Home profiles build via `home-manager --flake .#gabz@hermes switch`; the flake already passes `inputs` and `outputs` through `extraSpecialArgs`, so modules can assume they are available.
- When touching secrets, update `hosts/common/secrets.yaml` with `sops` inside the dev shell; `hosts/common/global/sops.nix` maps host SSH keys to age recipients and `users.gabz` pulls `gabz-password`.
- Persistence is opt-in: `/persist` is prepared by `hosts/common/global/optin-persistence.nix`, while each home module lists directories to keep under `home.persistence`.
- Hydra CI is described in `hydra.nix`, which filters redistributable derivations and exposes builds for `packages`, `nixosConfigurations`, and `homeConfigurations`.
- Graphics wrappers rely on `inputs.nix-gl`; see `home/gabz/hermes.nix` for enabling `nixGL` with Vulkan and wrapping Hyprland.
- Non-NixOS sessions are supported via `targets.genericLinux.enable` in `home/gabz/hermes.nix`, which expects `nixGL` wrapper scripts.
- For new modules, follow the pattern of taking `{ inputs, outputs, ... }` and appending to `imports`; this keeps them compatible with the automatic wiring in `flake.nix`.
- Test new or modified packages with `nix build .#packages.$SYSTEM.<name>` and consider adding them to `hydra.nix` so CI keeps building them.
- Existing keybindings and UI helpers live in feature modules (e.g. `home/gabz/features/desktop/hyprland`), so keep brightness/audio bindings aligned with `swayosd` and `brightnessctl` when editing.
- Sample Nix-enabled project templates reside under `templates/python/`; mirror their structure when adding new language templates.
- Wrap up every task by running `alejandra .` (formats the repo) and `nix flake check`; fix formatter or evaluation failures before you consider the work complete.

## MCP tools for this repo

- `#mcp_oraios_serena_activate_project` — initialize the workspace context before using other Serena tools so symbol lookups point at this flake.
- `#mcp_oraios_serena_onboarding` — run once if onboarding metadata is missing; it unblocks subsequent Serena analysis requests.
- `#mcp_oraios_serena_get_symbols_overview` — list top-level symbols in a file; helpful before touching complex modules under `hosts/**` or `home/gabz/features/**`.
- `#mcp_oraios_serena_list_memories` / `#mcp_oraios_serena_read_memory` — surface stored repo notes (e.g. host quirks) before large refactors.
- `#mcp_oraios_serena_think_about_task_adherence`, `#mcp_oraios_serena_think_about_collected_information`, `#mcp_oraios_serena_think_about_whether_you_are_done`, and `#think` — reflection helpers to double-check plan coverage, collected context, and completion criteria.
- `#codebase` — run semantic searches across the repo when you need to locate patterns that cross `hosts`, `modules`, and `pkgs`.
- `#fetch_webpage` or `#mcp_misterio77_ni_fetch_generic_url_content` — pull upstream docs or blog posts referenced in configuration comments and module notes.
- `#Misterio77/nix-config nix-config template Docs` — fetch rationale from the upstream template; note this fork diverges, so reconcile findings with local overrides.
- `#mcp_cognitionai_d_ask_question` — query external GitHub repositories (e.g., upstream modules) when patching overlays in `overlays/default.nix`.
- `#mcp_upstash_conte_get-library-docs` — retrieve up-to-date docs for third-party libraries (such as Hyprland or sops) when adjusting feature modules.
- `#mcp_nixos_nixos_search`, `#mcp_nixos_nixos_info`, `#mcp_nixos_nixos_channels`, `#mcp_nixos_nixos_stats`, `#mcp_nixos_nixos_flakes_search`, `#mcp_nixos_nixos_flakes_stats` — audit NixOS options, channel health, and candidate flakes before updating `hosts/**` or `flake.nix`.
- `#mcp_nixos_nixhub_find_version` / `#mcp_nixos_nixhub_package_versions` — verify package versions available in nixpkgs when maintaining `pkgs/*` derivations or overlays.
- `#mcp_nixos_home_manager_search`, `#mcp_nixos_home_manager_options_by_prefix`, `#mcp_nixos_home_manager_list_options`, `#mcp_nixos_home_manager_info`, `#mcp_nixos_home_manager_stats` — explore Home Manager options relevant to `home/gabz/**` modules.
