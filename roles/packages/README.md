# packages

System and user-level package installation for development hosts.

Uses `become: true` for system packages, dispatches per-distro tasks via `ansible_facts.os_family` (Debian / RedHat).

## What it does

- Installs distro-specific system packages (Debian.yml / RedHat.yml)
- Installs extra system packages configurable per distro
- Installs a pinned Node.js version from the official tarball
- Downloads versioned CLI binaries from GitHub releases (kubectl, helm, kustomize, virtctl, argocd, flux, kubeseal, tkn, terraform, sops, oc, kubeconform, kube-burner, kube-burner-ocp, act, mc, rclone)
- Installs pip packages (ansible-core, ansible-navigator, molecule, etc.)
- Installs devcontainer CLI via npm
- Optionally installs Claude Code, Cursor agent CLI, GitHub CLI, and 1Password

## Role Variables

### Feature flags

Each tool can be individually enabled or disabled:

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
| `packages_install_argocd` | `true` | Install ArgoCD CLI |
| `packages_install_flux` | `true` | Install Flux CLI |
| `packages_install_kubeseal` | `true` | Install kubeseal (Sealed Secrets) |
| `packages_install_tkn` | `true` | Install Tekton CLI |
| `packages_install_terraform` | `true` | Install Terraform |
| `packages_install_sops` | `true` | Install SOPS |
| `packages_install_oc` | `true` | Install OpenShift CLI |
| `packages_install_kubeconform` | `true` | Install kubeconform |
| `packages_install_kube_burner` | `true` | Install kube-burner |
| `packages_install_kube_burner_ocp` | `true` | Install kube-burner-ocp |
| `packages_install_act` | `true` | Install act (local GitHub Actions runner) |
| `packages_install_mc` | `true` | Install MinIO Client |
| `packages_install_rclone` | `true` | Install rclone |
| `packages_install_extra_packages` | `true` | Install extra system packages |
| `packages_install_nodejs_pinned` | `true` | Install pinned Node.js |
| `packages_install_pip_packages` | `true` | Install pip packages |

### Version pins (Renovate-managed)

| Variable | Default | Description |
|---|---|---|
| `packages_nodejs_version` | `"v24.14.1"` | Node.js version |
| `packages_devcontainer_cli_version` | `"0.85.0"` | devcontainer CLI version |
| `packages_kubectl_version` | `"v1.35.3"` | kubectl version |
| `packages_helm_version` | `"v4.1.3"` | Helm version |
| `packages_kustomize_version` | `"v5.8.1"` | Kustomize version |
| `packages_virtctl_version` | `"v1.8.0"` | virtctl version |
| `packages_argocd_version` | `"v3.3.4"` | ArgoCD CLI version |
| `packages_flux_version` | `"v2.8.3"` | Flux CLI version |
| `packages_kubeseal_version` | `"v0.36.1"` | kubeseal version |
| `packages_tkn_version` | `"v0.44.0"` | Tekton CLI version |
| `packages_terraform_version` | `"v1.14.8"` | Terraform version |
| `packages_sops_version` | `"v3.12.2"` | SOPS version |
| `packages_oc_version` | `"latest"` | OpenShift CLI version |
| `packages_kubeconform_version` | `"v0.7.0"` | kubeconform version |
| `packages_kube_burner_version` | `"v2.4.2"` | kube-burner version |
| `packages_kube_burner_ocp_version` | `"v1.11.4"` | kube-burner-ocp version |
| `packages_act_version` | `"v0.2.84"` | act version |
| `packages_rclone_version` | `"v1.73.2"` | rclone version |

### Package lists

| Variable | Default | Description |
|---|---|---|
| `packages_extra_packages_debian` | *(see defaults)* | Extra apt packages to install on Debian/Ubuntu |
| `packages_extra_packages_redhat` | *(see defaults)* | Extra dnf packages to install on RHEL/CentOS |
| `packages_pip_packages` | *(see defaults)* | Pip packages to install (Renovate-managed versions) |
| `packages_pip_requirements` | `""` | Path to a pip requirements file (skipped when empty) |

## Dependencies

None.
