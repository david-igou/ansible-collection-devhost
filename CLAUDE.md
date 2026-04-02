# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`david_igou.devhost` — an Ansible collection that provisions a bare Linux host for VS Code/Cursor remote-server and devcontainer workflows. It installs packages, configures rootless Podman, and sets up user-level directories/git config.

## Commands

```bash
# Lint roles and playbooks
ansible-lint roles/ playbooks/

# Syntax check
ansible-playbook playbooks/site.yml --syntax-check

# Dry-run against localhost
ansible-playbook playbooks/site.yml -c local --check --diff -K

# Run the full provisioning playbook
ansible-playbook david_igou.devhost.site -c local -K

# Pre-commit hooks (prettier, flake8, isort, black, trailing whitespace)
pre-commit run --all-files
```

## Architecture

This is a Galaxy collection (namespace `david_igou`, name `devhost`). `galaxy.yml` at repo root defines metadata and dependencies (`community.general`, `ansible.posix`).

### Roles

- **host_prep** — User-level setup (no `become`): creates bind-mount target directories, seed files (`~/.gitconfig`, `~/.claude.json`), git user/email config, GitHub SSH URL rewrite. Runs first since other roles may depend on directories it creates.
- **packages** — All package installs (`become: true` for system packages). Uses `include_tasks: "{{ ansible_os_family }}.yml"` to dispatch Debian vs RedHat package manager tasks. Shared post-install tasks (devcontainer CLI, Claude Code, Cursor agent) run without become.
- **podman_rootless** — Kernel tuning via `ansible.posix.sysctl`, subuid/subgid configuration, podman socket activation (user scope), optional docker.sock symlink. Depends on `packages` role (declared in `meta/main.yml`).

### Key conventions

- **Variable prefix**: All role variables use `devhost_` as a collection-wide prefix (not per-role), since variables are intentionally shared across roles (e.g., `devhost_install_onepassword` is used by both `packages` and `host_prep`).
- **Multi-distro dispatch**: Per-distro task files named `Debian.yml` / `RedHat.yml`, included via `ansible_os_family`.
- **Become strategy**: No `become: true` at play level. Each task declares it individually — package installs and system config use become; user-level tasks do not.
- **Version pinning**: Renovate manages versions via `# renovate:` annotations in role defaults. See `renovate.json` for the custom manager regex.

### Playbook

`playbooks/site.yml` is the entry point — runs `host_prep` → `packages` → `podman_rootless` in order.

## Upstream agent guidance

Per `AGENTS.md`, follow practices from the [ansible-creator agents doc](https://raw.githubusercontent.com/ansible/ansible-creator/refs/heads/main/docs/agents.md).
