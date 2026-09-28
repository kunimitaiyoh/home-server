# home-server

Configuration management for the single home server `radio` (MINISFORUM X1 Lite-255, Ubuntu Server 26.04 LTS). This repository is dedicated to `radio` — do not generalize it for multiple hosts (no `roles/`, no host-specific directory hierarchies).

## Responsibilities

- System-wide OS state: Ansible (`ansible/`).
- Userland: Nix + Home Manager standalone with Flakes (`nix/`, flake output `homeConfigurations.radio`).
- Orchestration: `apply.sh` — a thin wrapper that runs Ansible, then Home Manager. It must hold no configuration-management logic. Each tool must also remain directly runnable on its own.
- `bootstrap.sh` installs Git and Ansible via apt, nothing more. Do not grow it.
- Nix itself is installed by Ansible (official installer, multi-user). Never invoke Home Manager from Ansible.
- Do not manage the same package or setting in both apt/Ansible and Nix/Home Manager.

## Design principles

- Ansible must be idempotent. Use dedicated modules instead of `shell`/`command`; the accepted exceptions are the Nix installer invocation guarded by `creates` and the `netplan apply` handler, which runs only when notified by a configuration change.
- The playbook is a single `site.yaml`. Split it into task files only when it actually grows too large.
- Reproducibility: `flake.lock` is committed. `nixpkgs` tracks the current stable branch; `nixos-unstable` is used only for fast-moving packages (claude-code, codex, opencode).

## Conventions

- YAML files use the `.yaml` extension.
- Host-specific values live in `ansible/vars.yaml` only. Keep the literal `radio` out of filenames and other configuration.
- Files deployed by Ansible are named after their manager, e.g. `/etc/netplan/50-ansible.yaml`, `/etc/ssh/sshd_config.d/50-ansible.conf` (following the `50-cloud-init` naming style).
- Never commit secrets (private keys, passwords, tokens). Public keys may be committed. No secret-management framework until actually needed.
