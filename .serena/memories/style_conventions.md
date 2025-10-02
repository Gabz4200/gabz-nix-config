# Style and Conventions
- Modules accept `{ inputs, outputs, lib, pkgs, ... }` and extend `imports` instead of rewriting shared lists to stay compatible with auto-import wiring from `flake.nix`.
- Host configs live under `hosts/<name>/`; import order keeps hardware, global defaults, then optional modules, ending with host overrides. Use `lib.mkDefault`/`mkForce` sparingly for overrides already seen in repo.
- Home Manager features reside in `home/gabz/features/**`; compose them by adding to the `imports` array in the target profile (`home/gabz/<machine>.nix`). Reuse colors via `config.colorscheme` and helper scripts from `home/gabz/global`.
- Overlays modify packages with `addPatches` and `overrideAttrs`; prefer appending to existing patch lists and keep comments referencing upstream issues.
- Persisted paths go in `home.persistence` (user) or `environment.persistence` (system); follow existing pattern to avoid breaking impermanence.
- Keybinding tweaks for Hyprland should stay aligned with `swayosd`, `brightnessctl`, and playerctl helpers defined in the feature module.
- Secrets must reference `hosts/common/secrets.yaml` via `sops.secrets`; never hardcode secrets in modules.
- Always run the VS Code `NixOS MCP` command before editing `.nix` files and again after saving to refresh metadata and catch evaluation issues early.
- Formatting: rely on `alejandra` (the flake formatter) for Nix files; avoid manual reflow beyond substantive changes.