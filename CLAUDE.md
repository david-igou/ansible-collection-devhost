# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`david_igou.devhost` — an Ansible collection that provisions a bare Linux host for VS Code/Cursor remote-server and devcontainer workflows. It installs packages, configures rootless Podman, and sets up user-level directories/git config.

## Commands

```bash
# Lint (uses .ansible-lint config with production profile)
ansible-lint

# Syntax check
ansible-playbook playbooks/site.yml --syntax-check

# Dry-run against localhost
ansible-playbook playbooks/site.yml -c local --check --diff -K

# Run the full provisioning playbook
ansible-playbook david_igou.devhost.site -c local -K

# Pre-commit hooks (prettier, trailing whitespace, end-of-file)
pre-commit run --all-files
```

## Architecture

This is a Galaxy collection (namespace `david_igou`, name `devhost`). `galaxy.yml` at repo root defines metadata and dependencies (`community.general`, `ansible.posix`).

### Roles

- **host_prep** — User-level setup (no `become`): creates bind-mount target directories, seed files (`~/.gitconfig`, `~/.claude.json`), git user/email config, GitHub SSH URL rewrite. Runs first since other roles may depend on directories it creates.
- **packages** — All package installs (`become: true` for system packages). Uses `include_tasks: "{{ ansible_facts.os_family }}.yml"` to dispatch Debian vs RedHat package manager tasks. Shared post-install tasks (devcontainer CLI, Claude Code, Cursor agent) run without become.
- **podman** — Podman host configuration: kernel tuning via `ansible.posix.sysctl`, subuid/subgid configuration, podman socket activation (user scope), optional docker.sock symlink. Rootless-specific tasks are gated behind `podman_rootless` (default `true`). Depends on `packages` role (declared in `meta/main.yml`).

### Key conventions

- **Variable prefix**: Each role prefixes its variables with the role name (e.g., `host_prep_`, `packages_`, `podman_`). Internal register variables use a double-underscore prefix (e.g., `__podman_subuid_result`). Cross-role references use the owning role's prefix (e.g., `host_prep` references `packages_install_onepassword`).
- **Multi-distro dispatch**: Per-distro task files named `Debian.yml` / `RedHat.yml`, included via `ansible_facts.os_family`.
- **Become strategy**: No `become: true` at play level. Each task declares it individually — package installs and system config use become; user-level tasks do not.
- **Version pinning**: Renovate manages versions via `# renovate:` annotations in role defaults. See `renovate.json` for the custom manager regex.

### Playbook

`playbooks/site.yml` is the entry point — runs `host_prep` → `packages` → `podman` in order.

## Testing

### Running molecule

```bash
# Run a specific scenario (host_prep, packages, default, podman)
molecule test -s host_prep

# Converge only (skip destroy — useful during development)
molecule converge -s host_prep

# Run verify step against an already-converged instance
molecule verify -s host_prep
```

Molecule scenarios live in `extensions/molecule/<scenario>/`. Each scenario has `converge.yml`, `verify.yml`, and `molecule.yml`.

### Provisioner abstraction

Scenarios use a pluggable provisioner pattern. Each `molecule.yml` references shared provisioner files via the `PROVISIONER` env var (defaults to `podman`):

```yaml
provisioner:
  playbooks:
    create: ../provisioners/${PROVISIONER:-podman}/create.yml
    destroy: ../provisioners/${PROVISIONER:-podman}/destroy.yml
    prepare: ../provisioners/${PROVISIONER:-podman}/prepare.yml
  inventory:
    links:
      group_vars: ../provisioners/${PROVISIONER:-podman}/group_vars/
```

Each provisioner directory (`extensions/molecule/provisioners/<name>/`) contains `create.yml`, `destroy.yml`, `prepare.yml`, `requirements.yml`, and `group_vars/all.yml`. Platform entries in `molecule.yml` carry config for each provisioner under namespaced keys (`podman:`, `kubevirt:`), and the active provisioner reads only its own key.

Available provisioners:

- **podman** (default) — Spins up rootless Podman containers via `containers.podman`. Connection: `containers.podman.podman`. Used in CI.
- **kubevirt** — Creates KubeVirt VirtualMachine resources on an OpenShift/Kubernetes cluster via `kubernetes.core`. Generates an ephemeral SSH keypair, injects it via cloud-init, and exposes SSH through a NodePort service. Connection: `ssh`. Set `MOLECULE_NAMESPACE` to control the target namespace. Two disk strategies are supported — by default VMs use a lightweight containerdisk (ephemeral COW root); set `disk_size` to use a DataVolume-backed root disk with a full-size filesystem (requires CDI and a default StorageClass):

```yaml
# containerdisk (default — no storage provider needed):
kubevirt:
  image: quay.io/containerdisks/ubuntu:24.04

# DataVolume (sized root disk):
kubevirt:
  image: quay.io/containerdisks/ubuntu:24.04
  disk_size: 10Gi
```

To run with a non-default provisioner:

```bash
PROVISIONER=kubevirt molecule test -s packages
```

### Smoke testing

Every molecule scenario must include a `verify.yml` that smoke-tests the converged state. Smoke tests should:

- Verify services are functioning after deployment (check ports, sockets, CLI commands).
- Use `ansible.builtin.stat` + `ansible.builtin.assert` for files and directories.
- Use `ansible.builtin.command` + `changed_when: false` for CLI health checks.
- Assert on specific expected values, not just existence.
- Fail fast — if a smoke test fails, the scenario fails.
- Finish with a `debug` task summarizing what was verified.

Do **not** remove the `verify` step from `molecule.yml` test sequences.

### CI scenarios

CI runs `host_prep` and `packages` scenarios. `default` and `podman` are available locally but excluded from CI.

## Coding standards

These are derived from the [upstream agents doc](https://raw.githubusercontent.com/ansible/ansible-creator/refs/heads/main/docs/agents.md). Run `ansible-lint` to enforce most of these automatically.

### YAML formatting

- Use two-space indentation.
- Use `.yml` extension for all YAML files.
- Use double quotes for YAML strings; use single quotes for Jinja2 expressions.
- Use `true`/`false` for booleans, never `yes`/`no` or `True`/`False`.
- Spell out task arguments in YAML style, not `key=value` format.
- Use `>-` (not `>`) for folded scalars; break long `when` conditions into lists.
- Keep lines under 160 characters.
- Start YAML files with `---`.

### Fully qualified collection names

Always use FQCNs for all modules and plugins: `ansible.builtin.copy`, not `copy`. Use `ansible.builtin` for core modules. Avoid the `collections` keyword.

### Task naming

- All tasks, plays, and blocks must have a `name`.
- Write names in imperative form, starting with an uppercase letter (e.g., "Install podman packages").
- Do not use variables in play names (they don't expand properly).
- Task names should be unique within a play.

### Module and command usage

- Prefer specific modules over `command` or `shell` (e.g., use `ansible.builtin.package` instead of `apt`/`dnf` via shell).
- When `command`/`shell` is unavoidable, always set `changed_when` (and/or `creates`/`removes`).
- Add a `# noqa` comment with justification when suppressing lint rules for command usage.
- Always explicitly specify `state` in modules — do not rely on defaults.

### Idempotency

- All tasks must produce no changes on a second run.
- Use `changed_when` with `command`/`shell` to accurately reflect change state.
- Support check mode (`--check`) — tasks should not fail in check mode.
- Use handlers (via `notify`) instead of `when: foo_result is changed`.

### Role design

- Define role arguments in `meta/argument_specs.yml` for validation.
- All external arguments should have defaults in `defaults/main.yml`.
- Use `vars/main.yml` only for constants and magic values (high precedence).
- Do not override role defaults with `set_fact`.
- Keep roles focused on a single outcome with limited scope.

## Git workflow

- **Do not modify git remote URLs or global git config.** The remote is set to `git@github.com:` (SSH) for the repository owner. Never change it to HTTPS, and never run `gh auth setup-git` or configure credential helpers — these overwrite the SSH-based remote and break the owner's push access.
- **Pushing with `GITHUB_TOKEN`/`GH_TOKEN`**: If you need to push and only have a token (no SSH key), use `gh` CLI directly instead of `git push`. For example: `gh pr create`, or push a branch via the GitHub API. **Do not reconfigure the remote or credential helper to make `git push` work with a token.**
- **Pushing with SSH**: If an SSH key is available, just run `git push` — the remote is already configured for SSH.
- **Pre-push gate**: Always run `ansible-lint` before pushing and fix any violations. Do not push code that fails linting.
- **KubeVirt validation**: If the `KUBECONFIG` environment variable is set, run `make molecule-kubevirt` before pushing and ensure it passes. Do not push code that fails molecule-kubevirt tests when a cluster is available.

## Upstream agent guidance

Per `AGENTS.md`, follow practices from the [ansible-creator agents doc](https://raw.githubusercontent.com/ansible/ansible-creator/refs/heads/main/docs/agents.md).
