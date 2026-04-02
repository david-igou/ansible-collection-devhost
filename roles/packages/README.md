# packages

System and user-level package installation for development hosts.

Uses `become: true` for system packages, dispatches per-distro tasks via `ansible_facts.os_family` (Debian / RedHat).

## What it does

- Installs distro-specific system packages (Debian.yml / RedHat.yml)
- Installs devcontainer CLI via npm
- Optionally installs Claude Code, Cursor agent CLI, GitHub CLI, and 1Password

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `packages_install_onepassword` | `true` | Install 1Password CLI |
| `packages_install_github_cli` | `true` | Install GitHub CLI |
| `packages_install_claude_code` | `true` | Install Claude Code |
| `packages_install_cursor_agent` | `true` | Install Cursor agent CLI |
| `packages_devcontainer_cli_version` | `"0.85.0"` | Pinned devcontainer CLI version (Renovate-managed) |

## Dependencies

None.
