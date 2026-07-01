# packages

System and user-level package installation for development hosts.

Uses `become: true` for system packages, dispatches per-distro tasks via `ansible_facts.os_family` (Debian / RedHat). CLI binaries are installed by **mise**, which is distro-agnostic — the same binaries on Debian and RedHat.

## What it does

- Installs distro-specific system packages (Debian.yml / RedHat.yml) + a configurable extra package list.
- Installs and **version-pins CLI tools via mise** from `files/mise.toml` (kubectl, helm, kustomize, virtctl, argocd, flux, kubeseal, tkn, terraform, sops, oc, kubeconform, kube-burner, kube-burner-ocp, act, mc, rclone, and Node.js). The mise binary is installed from a GPG-pinned tarball; tools are verified per `files/mise.lock` (SHA256/blake3), SLSA/attestations, and GPG postinstall hooks for helm/terraform/oc; then symlinked into `/usr/local/bin`.
- Installs pip packages (ansible-core, ansible-navigator, molecule, etc.).
- Installs the devcontainer CLI via npm (uses Node.js from mise).
- Optionally installs Claude Code, Cursor agent CLI, GitHub CLI, and 1Password.

## Role Variables

### Feature flags

| Variable | Default | Description |
|---|---|---|
| `packages_install_cli_tools` | `true` | Install + version-pin the CLI tool set (and Node.js) via mise from `files/mise.toml`. When false, a distro Node.js package is installed as a fallback so the devcontainer CLI still works |
| `packages_install_onepassword` | `true` | Install 1Password CLI (distro repo) |
| `packages_install_github_cli` | `true` | Install GitHub CLI (distro repo) |
| `packages_install_claude_code` | `true` | Install Claude Code |
| `packages_install_cursor_agent` | `true` | Install Cursor agent CLI |
| `packages_install_extra_packages` | `true` | Install extra system packages |
| `packages_install_pip_packages` | `true` | Install pip packages |

### mise

| Variable | Default | Description |
|---|---|---|
| `packages_mise_version` | `"v2026.6.11"` | mise binary version (GPG-pinned tarball; Renovate-managed) |
| `packages_mise_gpg_fpr` | `24853EC9…A06D` | Pinned GPG fingerprint for the mise tarball |
| `packages_mise_gpg_url` | `https://mise.jdx.dev/gpg-key.pub` | mise signing key URL |
| `packages_mise_config_dir` | `/etc/mise` | Where `mise.toml`, `mise.lock`, and the postinstall hooks are deployed |
| `packages_mise_data_dir` | `/opt/mise` | mise tool data dir (`MISE_DATA_DIR`) |
| `packages_github_token` | env `GITHUB_TOKEN` | Token for `mise install` (raises the GitHub API rate limit; strongly recommended) |

> **CLI tool versions live in `files/mise.toml`** (the single source of truth), not in role vars. Renovate bumps them via its native `mise` manager. After a bump, regenerate the lock with `make mise-lock` and commit `files/mise.toml` + `files/mise.lock` together. `files/mise-expected-verification.toml` + `files/test-mise-verification.sh` audit that each tool keeps its expected verification method.

### Other pins & lists

| Variable | Default | Description |
|---|---|---|
| `packages_devcontainer_cli_version` | `"0.85.0"` | devcontainer CLI version (npm) |
| `packages_extra_packages_debian` | *(see defaults)* | Extra apt packages on Debian/Ubuntu |
| `packages_extra_packages_redhat` | *(see defaults)* | Extra dnf packages on RHEL/CentOS |
| `packages_pip_packages` | *(see defaults)* | Pip packages (Renovate-managed) |
| `packages_pip_requirements` | `""` | Path/URL to a pip requirements file (skipped when empty) |

## Dependencies

None (uses `community.general.npm` from the collection's declared dependencies).
