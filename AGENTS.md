<!-- cspell: ignore SSOT CMDB -->

# AGENTS.md

## Upstream practices

Ensure that all practices and instructions described by
<https://raw.githubusercontent.com/ansible/ansible-creator/refs/heads/main/docs/agents.md>
are followed.

## Collection overview

`david_igou.devhost` is an Ansible collection that provisions a bare Linux host for VS Code/Cursor remote-server and devcontainer workflows. It targets Debian (bookworm), Ubuntu (jammy/noble), and RHEL/CentOS 9.

## Roles

| Role | Purpose | Uses `become` |
|---|---|---|
| `host_prep` | User-level setup: directories, seed files, git config, SSH rewrite, repo cloning | No |
| `packages` | System packages, third-party repos, versioned CLI binaries, pip packages | Yes (system packages) |
| `podman` | Podman installation, kernel tuning, rootless config, socket activation | Yes (packages, sysctl) |
| `docker` | Docker CE lifecycle: repo, CLI, compose, daemon, rootless | Yes (packages, service) |

The entry-point playbook (`playbooks/site.yml`) runs: `packages` -> `host_prep` -> `podman` -> `docker`.

## Key conventions

- **Variable prefix**: Each role prefixes its variables with the role name (`host_prep_`, `packages_`, `podman_`, `docker_`). Internal registers use double-underscore prefix (`__podman_subuid_result`).
- **FQCNs**: Always use fully qualified collection names (`ansible.builtin.copy`, not `copy`).
- **Multi-distro dispatch**: Per-distro task files named `Debian.yml` / `RedHat.yml`, included via `ansible_facts.os_family`.
- **Become strategy**: No `become: true` at play level. Each task declares it individually.
- **Version pinning**: Renovate manages versions via `# renovate:` annotations in role defaults.
- **Booleans**: Use `true`/`false`, never `yes`/`no`.
- **Strings**: Use double quotes for YAML strings; single quotes for Jinja2 expressions.

## Testing

Molecule scenarios in `extensions/molecule/`. Run with `molecule test -s <scenario>`.

Available scenarios: `host_prep`, `packages`, `podman`, `docker`, `container_runtimes`, `default`.

CI runs `host_prep`, `packages`, `docker`, and `podman` scenarios. Use `PROVISIONER=kubevirt` for VM-based testing.

## Validation commands

```bash
ansible-lint                                    # Lint
ansible-playbook playbooks/site.yml --syntax-check  # Syntax check
molecule test -s <scenario>                     # Molecule test
make test                                       # Lint + molecule
```
