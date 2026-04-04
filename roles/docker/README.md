# docker

Docker CE daemon installation and configuration.

## What it does

- Installs Docker CE and containerd via distro-specific package managers
- Deploys `/etc/docker/daemon.json` with configurable storage driver, log driver, registry mirrors, and arbitrary options
- Manages `docker` group membership for socket access
- Enables and starts `docker.service`
- Optionally installs `docker-ce-rootless-extras` and configures rootless Docker for the target user

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `docker_enabled` | `true` | Gate for all role tasks; set to `false` to skip |
| `docker_rootless` | `false` | Install rootless extras and configure user-scoped Docker |
| `docker_storage_driver` | `"overlay2"` | Storage driver for daemon.json |
| `docker_log_driver` | `"journald"` | Default container logging driver |
| `docker_live_restore` | `true` | Keep containers running across daemon restarts |
| `docker_registry_mirrors` | `[]` | Registry mirror URLs (included in daemon.json when non-empty) |
| `docker_insecure_registries` | `[]` | Insecure registry list (included in daemon.json when non-empty) |
| `docker_daemon_options` | `{}` | Arbitrary keys merged into daemon.json (highest precedence) |
| `docker_group_members` | `["{{ ansible_facts.user_id }}"]` | Users to add to the `docker` group |

## Dependencies

- `david_igou.devhost.packages` (Docker CE repo setup and CLI are handled by the packages role)
