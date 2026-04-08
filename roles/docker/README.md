# docker

Docker CE installation and configuration.

## What it does

- Sets up the Docker CE repository for the target distro (Debian/RedHat)
- Removes podman-docker to avoid file conflicts on /usr/bin/docker
- Installs docker-ce-cli and docker-compose-plugin
- Optionally installs the Docker daemon (docker-ce, containerd.io)
- Deploys `/etc/docker/daemon.json` with configurable storage driver, log driver, registry mirrors, and arbitrary options
- Manages `docker` group membership for socket access
- Enables and starts `docker.service`
- Optionally installs `docker-ce-rootless-extras` and configures rootless Docker for the target user

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `docker_enabled` | `true` | Gate for all role tasks; set to `false` to skip |
| `docker_install_cli` | `true` | Install docker-ce-cli from the Docker CE repository |
| `docker_install_compose_plugin` | `true` | Install docker-compose-plugin |
| `docker_install_daemon` | `true` | Install docker-ce and containerd.io, deploy daemon.json, enable service |
| `docker_rootless` | `false` | Install rootless extras and configure user-scoped Docker |
| `docker_storage_driver` | `"overlay2"` | Storage driver for daemon.json |
| `docker_log_driver` | `"journald"` | Default container logging driver |
| `docker_live_restore` | `true` | Keep containers running across daemon restarts |
| `docker_registry_mirrors` | `[]` | Registry mirror URLs (included in daemon.json when non-empty) |
| `docker_insecure_registries` | `[]` | Insecure registry list (included in daemon.json when non-empty) |
| `docker_daemon_options` | `{}` | Arbitrary keys merged into daemon.json (highest precedence) |
| `docker_group_members` | `["{{ ansible_facts.user_id }}"]` | Users to add to the `docker` group |

## Breaking changes from packages role

The following variables have been renamed:

| Old (packages role) | New (docker role) |
|---|---|
| `packages_install_docker_cli` | `docker_install_cli` |
| `packages_install_docker_compose_plugin` | `docker_install_compose_plugin` |

## Dependencies

None. This role manages its own repository setup and package installation.
