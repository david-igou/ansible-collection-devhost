# david_igou.devhost

![Galaxy Version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fgalaxy.ansible.com%2Fapi%2Fv3%2Fplugin%2Fansible%2Fcontent%2Fpublished%2Fcollections%2Findex%2Fdavid_igou%2Fdevhost%2F&query=%24.highest_version.version&label=galaxy)
![Ansible](https://img.shields.io/badge/ansible-%3E%3D2.16-blue?logo=ansible)
![CI](https://img.shields.io/github/actions/workflow/status/david-igou/ansible-collection-devhost/tests.yml?branch=main&label=CI)
![License](https://img.shields.io/github/license/david-igou/ansible-collection-devhost)
![Last Commit](https://img.shields.io/github/last-commit/david-igou/ansible-collection-devhost)

Ansible collection that provisions a bare Linux host for VS Code/Cursor remote-server and devcontainer workflows. It installs system and CLI packages, configures rootless Podman and/or Docker CE, and sets up user-level directories, git config, and seed files.

## Requirements

- Ansible >= 2.16
- Supported platforms: Debian (bookworm), Ubuntu (jammy, noble), RHEL/CentOS 9

### Collection dependencies

| Collection | Version |
|---|---|
| `community.general` | >= 8.0.0 |
| `ansible.posix` | >= 1.5.0 |

## Included roles

| Role | Description |
|---|---|
| [`host_prep`](roles/host_prep/) | User-level setup: bind-mount directories, seed files, git config, SSH rewrite, repository cloning |
| [`packages`](roles/packages/) | System packages, third-party repos, versioned CLI binaries, pip packages, devcontainer CLI |
| [`podman`](roles/podman/) | Podman installation, kernel tuning, rootless config, socket activation, storage config |
| [`docker`](roles/docker/) | Docker CE lifecycle: repo setup, CLI, compose plugin, daemon config, rootless mode |

## Installation

```bash
ansible-galaxy collection install david_igou.devhost
```

Or in a `requirements.yml`:

```yaml
---
collections:
  - name: david_igou.devhost
```

## Usage

The entry-point playbook runs all roles in order against the `devhosts` host group:

```bash
ansible-playbook david_igou.devhost.site -c local -K
```

Dry-run with diff output:

```bash
ansible-playbook david_igou.devhost.site -c local --check --diff -K
```

Each role can also be used independently:

```yaml
---
- name: Install packages only
  hosts: devhosts
  gather_facts: true
  roles:
    - role: david_igou.devhost.packages
```

## Testing

[Molecule](https://ansible.readthedocs.io/projects/molecule/) scenarios live in `extensions/molecule/`. Available scenarios: `host_prep`, `packages`, `podman`, `docker`, `container_runtimes`, `default`.

```bash
# Run a specific scenario
molecule test -s packages

# Converge only (skip destroy)
molecule converge -s host_prep

# Run verify against an already-converged instance
molecule verify -s host_prep
```

### Provisioners

Scenarios use a pluggable provisioner pattern (default: `podman`). Set the `PROVISIONER` env var to switch:

```bash
# Run with KubeVirt VMs instead of containers
PROVISIONER=kubevirt molecule test -s packages
```

Available provisioners: `podman` (CI default), `kubevirt` (OpenShift/Kubernetes VMs).

### Makefile targets

```
make lint               # Run ansible-lint
make molecule           # Run molecule test (SCENARIO=default PROVISIONER=podman)
make molecule-kubevirt  # Run molecule test against KubeVirt
make test               # Run lint then molecule
make collection-build   # Build the collection tarball
make collection-install # Build and install locally
```

## Release notes

See the [changelog fragments](changelogs/fragments/) for upcoming changes, or the generated [changelog](changelogs/) after release.

## License

GNU General Public License v3.0 or later. See [LICENSE](LICENSE).
