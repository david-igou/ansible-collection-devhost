# podman

Podman installation and host configuration including kernel tuning, user namespace setup, and rootless container support.

## What it does

- Installs podman, buildah, skopeo, fuse-overlayfs, slirp4netns, uidmap/shadow-utils, and catatonit
- Tunes `user.max_user_namespaces` and `net.ipv4.ip_unprivileged_port_start` via sysctl
- Configures subuid/subgid ranges for the target user
- Enables `loginctl` lingering so user systemd services persist across sessions
- Deploys user-level `~/.config/containers/containers.conf` (events logger, etc.)
- Deploys user-level `~/.config/containers/storage.conf` (driver, fuse-overlayfs, graphroot)
- Enables the podman user-scope socket (`podman.socket`)
- Optionally symlinks `/var/run/docker.sock` to the podman socket
- Optionally installs `podman-docker` compatibility package
- Warns if the storage driver is not `overlay`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `podman_rootless` | `true` | Gate rootless-specific tasks (sysctl, subuid/subgid, linger, socket activation) |
| `podman_docker_compat` | `false` | Install `podman-docker` compatibility package |
| `podman_subuid_start` | `100000` | Starting subuid/subgid value |
| `podman_subuid_count` | `65536` | Number of subordinate UIDs/GIDs |
| `podman_user_namespaces_max` | `28633` | `user.max_user_namespaces` sysctl value |
| `podman_unprivileged_port_start` | `0` | `net.ipv4.ip_unprivileged_port_start` sysctl value |
| `podman_docker_socket_symlink` | `true` | Create `/var/run/docker.sock` symlink |
| `podman_enable_linger` | `true` | Enable `loginctl` lingering for the user |
| `podman_configure_containers_conf` | `true` | Deploy user-level `containers.conf` |
| `podman_events_logger` | `"file"` | Podman events logger backend (`file`, `journald`, `none`) |
| `podman_configure_storage_conf` | `true` | Deploy user-level `storage.conf` |
| `podman_storage_driver` | `"overlay"` | Podman storage driver |
| `podman_storage_mount_program` | `"/usr/bin/fuse-overlayfs"` | Path to fuse-overlayfs (empty string for native overlay) |
| `podman_storage_graphroot` | `""` | Override graphroot path for rootless storage |

## Dependencies

None (manages its own package installation).
