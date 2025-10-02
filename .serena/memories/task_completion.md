# Task Completion Checklist
1. Check status with NixOS MCP Tools
2. Execute `alejandra .` from the repo root to format Nix files.
3. Run `nix flake check` to ensure evaluations, modules, and packages still succeed.
4. If the change targets a host or profile, optionally dry-run with `nixos-rebuild --flake .#<host> build` or `home-manager --flake .#gabz@hermes build`.
5. Review git diff, stage intentional changes, and craft a descriptive commit message once all checks pass.