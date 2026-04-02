# podman_rootless

Kernel tuning, user namespace setup, and podman socket activation for rootless containers.

## What it does

- Tunes `user.max_user_namespaces` and `net.ipv4.ip_unprivileged_port_start` via sysctl
- Configures subuid/subgid ranges for the target user
- Enables the podman user-scope socket (`podman.socket`)
- Optionally symlinks `/var/run/docker.sock` to the podman socket
- Warns if the storage driver is not `overlay`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `podman_rootless_subuid_start` | `100000` | Starting subuid/subgid value |
| `podman_rootless_subuid_count` | `65536` | Number of subordinate UIDs/GIDs |
| `podman_rootless_user_namespaces_max` | `28633` | `user.max_user_namespaces` sysctl value |
| `podman_rootless_unprivileged_port_start` | `0` | `net.ipv4.ip_unprivileged_port_start` sysctl value |
| `podman_rootless_socket_symlink` | `true` | Create `/var/run/docker.sock` symlink |

## Dependencies

- `david_igou.devhost.packages`
