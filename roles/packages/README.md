# packages

System and user-level package installation for development hosts.

Uses `become: true` for system packages, dispatches per-distro tasks via `ansible_facts.os_family` (Debian / RedHat).

## What it does

- Installs distro-specific system packages (Debian.yml / RedHat.yml)
- Downloads versioned CLI binaries from GitHub releases (kubectl, helm, kustomize, virtctl)
- Installs devcontainer CLI via npm
- Optionally installs Claude Code, Cursor agent CLI, GitHub CLI, and 1Password

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `packages_install_onepassword` | `true` | Install 1Password CLI |
| `packages_install_github_cli` | `true` | Install GitHub CLI |
| `packages_install_claude_code` | `true` | Install Claude Code |
| `packages_install_cursor_agent` | `true` | Install Cursor agent CLI |
| `packages_install_kubectl` | `true` | Install kubectl |
| `packages_install_helm` | `true` | Install Helm |
| `packages_install_kustomize` | `true` | Install Kustomize |
| `packages_install_virtctl` | `true` | Install virtctl (KubeVirt) |
| `packages_devcontainer_cli_version` | `"0.85.0"` | Pinned devcontainer CLI version (Renovate-managed) |
| `packages_kubectl_version` | `"v1.35.3"` | Pinned kubectl version (Renovate-managed) |
| `packages_helm_version` | `"v4.1.3"` | Pinned Helm version (Renovate-managed) |
| `packages_kustomize_version` | `"v5.8.1"` | Pinned Kustomize version (Renovate-managed) |
| `packages_virtctl_version` | `"v1.7.2"` | Pinned virtctl version (Renovate-managed) |

## Dependencies

None.
