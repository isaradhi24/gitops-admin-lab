# GitOps Admin Lab — Daily Startup & Shutdown Runbook

> **Environment:** MacBook Pro → Windows PC (`192.168.1.200`) → WSL Ubuntu-20.04 (`devops`) → Docker Desktop → kind cluster `gitops-admin` → Argo CD.  
> **Repository:** `isaradhi24/gitops-admin-lab`  
> **Goal:** Reuse the existing lab. **Do not recreate clusters or Azure resources during startup.**

## 0. Quick reference

| Item | Value / note |
| --- | --- |
| Windows host | `DESKTOP-VTJP961` |
| Windows LAN IP (verify daily) | `192.168.1.200` |
| WSL distro | `Ubuntu-20.04` |
| WSL user | `devops` |
| WSL IP (changes after restart) | Previously `172.24.208.178`; always recheck |
| SSH from Mac | `ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 2222 devops@192.168.1.200` |
| Windows forwarding | Windows `192.168.1.200:2222` → WSL `<CURRENT_WSL_IP>:22` |
| kind cluster | `gitops-admin` |
| kubectl context | `kind-gitops-admin` |
| Argo CD namespace | `argocd` |
| WSL repository | `/mnt/d/devops/gitops-admin-lab` |
| Mac repository | `~/Documents/DevOps/gitops-admin-lab` |

**Use the correct shell:** `PS C:\...>` = Windows PowerShell; `devops@DESKTOP...` = WSL Ubuntu; `MacBookPro:...` = macOS. Windows Git Bash (`isara@... MINGW64`) is **not** WSL.

## 1. Windows — start Docker Desktop

1. Open Docker Desktop and wait until it reports **Engine running**.
2. Open PowerShell and check WSL:

```powershell
wsl -l -v
```

3. Enter the Ubuntu environment if needed:

```powershell
wsl -d Ubuntu-20.04 -u devops
```

## 2. WSL — verify Docker and kind

```bash
docker version
kind get clusters
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
kubectl config use-context kind-gitops-admin
```

**Expected:** `gitops-admin-control-plane` and `gitops-admin-worker` are running. `devops-lab` and `jenkins-lab` should remain stopped during this session.

If **only** the GitOps node containers are stopped, start them without recreating the cluster:

```bash
docker start gitops-admin-control-plane gitops-admin-worker
```

Do not run `kind create cluster` or `kind delete cluster` as part of daily startup. If `docker start` fails, diagnose before changing anything.

## 3. WSL — check Kubernetes and Argo CD

```bash
kubectl config current-context
kubectl get nodes
kubectl get --raw='/readyz'
kubectl get pods -n kube-system
kubectl get pods -n argocd
kubectl get applications -n argocd
```

**Healthy target:** Both nodes `Ready`; `/readyz` returns `ok`; Argo CD components become `1/1` or otherwise ready as applicable; applications display their actual sync/health status. A node reporting `Ready` does **not** guarantee the API server or Argo CD is healthy.

If the API is unhealthy, **do not continue with deployments**. See Troubleshooting below. SSH connectivity can still be tested independently.

## 4. WSL — start SSH and capture its current IP

Ubuntu-20.04 in this lab does not use systemd as PID 1; **do not use `systemctl`** for SSH.

```bash
sudo service ssh status
sudo service ssh start   # only if not running
sudo service ssh status
hostname -I
```

Record the current WSL IP. Confirm SSH is running before testing from the Mac.

### SSH key setup (one-time unless keys change)

The Mac's **public** key `~/.ssh/id_ed25519.pub` must be installed in WSL as:

```text
/home/devops/.ssh/authorized_keys
```

On WSL:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
ssh-keygen -lf ~/.ssh/authorized_keys
```

On Mac:

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

The Mac public-key fingerprint must match an authorized key on WSL. Never copy or share the Mac **private** key. Windows Git Bash `C:\Users\isara\.ssh` is a different directory and does not authorize WSL `devops` login.

## 5. Windows PowerShell (Administrator) — verify forwarding

Check Windows LAN IP (prefer the active Ethernet/Wi-Fi adapter with a gateway):

```powershell
Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null } | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway
```

Check existing forwarding:

```powershell
netsh interface portproxy show all
```

Expected forwarding: `192.168.1.200:2222` → **today's** WSL IP on port `22`.

If the WSL IP changed, update **only the existing GitOps rule**, substituting the current IP:

```powershell
netsh interface portproxy delete v4tov4 listenaddress=192.168.1.200 listenport=2222
netsh interface portproxy add v4tov4 listenaddress=192.168.1.200 listenport=2222 connectaddress=<CURRENT_WSL_IP> connectport=22
netsh interface portproxy show all
```

If the rule does not exist, run only the `add` command. If Windows LAN IP changed, adjust `listenaddress` as well and verify the firewall rule. The lab firewall rule created previously is named **GitOps Lab WSL SSH**, scoped to Private networks, TCP 2222, and LocalSubnet.

```powershell
Get-NetFirewallRule -DisplayName 'GitOps Lab WSL SSH' | Select-Object DisplayName,Enabled,Profile
```

Check the Windows network profile if Mac access fails:

```powershell
Get-NetConnectionProfile
```

Do not create duplicate portproxy/firewall rules every day. Only update when addresses or settings change.

## 6. MacBook — SSH into WSL

```bash
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes -o ConnectTimeout=10 -p 2222 devops@192.168.1.200
```

Inside the SSH session:

```bash
whoami
hostname
kubectl config current-context
```

Expected: `devops`, `DESKTOP-VTJP961`, `kind-gitops-admin`.

> **Note:** This verifies **remote kubectl execution inside WSL**. It does not yet configure the Mac's *local* kubectl to access kind. Local Mac kubectl access requires a separately configured, secured API tunnel or endpoint and a matching kubeconfig. Do not copy the WSL kubeconfig blindly: kind commonly uses `127.0.0.1:<port>` that refers to WSL, not Mac.

## 7. Repository check (both machines)

On WSL and Mac, separately:

```bash
cd /path/to/gitops-admin-lab  # use the platform-specific path above
git status -sb
git remote -v
git fetch origin
git status -sb
```

If clean and behind remote, `git pull --ff-only origin main`. **Do not** blindly reset or overwrite uncommitted changes. Avoid editing the same branch on both machines without syncing.

## 8. Troubleshooting quick reference

| Symptom | First check / action |
| --- | --- |
| `systemctl`: not booted with systemd | Use `sudo service ssh status/start` |
| Mac → `172.24.x.x:22` times out | WSL NAT address is usually not reachable directly from Mac; use Windows LAN IP port 2222 |
| Mac → Windows port 2222 times out | Check Windows IP, WSL IP, `portproxy`, Private firewall profile, WSL sshd, and LAN reachability |
| `Permission denied (publickey)` | Network path works; check `/home/devops/.ssh/authorized_keys`, permissions, fingerprint, selected Mac identity |
| SCP to `isara@Windows` rejects password | Windows SSH is a separate account/service; do not assume its password is the WSL password; transfer public key through a trusted alternative |
| `kubectl` connection reset or `/readyz` fails | Check `kubectl get pods -n kube-system`; inspect API server/etcd health; don't deploy while unstable |
| etcd slow reads and API restarts | Inspect `docker exec gitops-admin-control-plane cat /proc/pressure/io`, `cat /proc/pressure/io`, `free -h`, disk latency; diagnose host storage |
| Only GitOps cluster needed | Keep `devops-lab` and `jenkins-lab` containers stopped; do not delete them |

### Known unresolved issue (2026-10-12)

Even after stopping other kind clusters, WSL I/O pressure remained extremely high (`some` approximately 97%, `full` approximately 84%), etcd read operations took multiple seconds, and `/readyz` intermittently failed (`etcd`, `etcd-readiness`, and sometimes `rbac/bootstrap-roles`). Free disk space and RAM were ample. **Root cause not yet isolated.** Investigate WSL/Docker storage latency before trusting Argo CD deployment status.

## 9. End-of-session shutdown (optional)

Save and push intended repository changes first. To stop **only** the GitOps kind nodes, preserving cluster containers:

```bash
docker stop gitops-admin-worker gitops-admin-control-plane
```

Next day use `docker start` from Step 2. Do **not** delete kind clusters, remove Docker volumes, delete Argo CD resources, or destroy Azure infrastructure as part of routine shutdown.

## 10. Still to document once validated

- Mac-local `kubectl` API tunnel, kubeconfig, and verification commands.
- Argo CD UI port-forward/tunnel and login procedure.
- Confirmed resolution of WSL/etcd I/O instability.
- Terraform backend lifecycle and GitHub Actions apply/destroy workflow once tested.
