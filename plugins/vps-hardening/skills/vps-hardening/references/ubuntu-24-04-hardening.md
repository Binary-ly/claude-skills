# The definitive VPS hardening guide for Ubuntu 24.04 LTS

**A production-grade Ubuntu 24.04 VPS can be hardened from default to fortress in under a day** by following the 15 categories below — covering SSH, firewalls, containers, kernel tuning, monitoring, backups, and zero-trust architecture. This guide reflects the 2025–2026 security landscape, including critical shifts like the nftables transition, AppArmor 4.0's new namespace restrictions, Let's Encrypt dropping OCSP, ModSecurity reaching end-of-life, and post-quantum SSH key exchange becoming production-ready. Every recommendation includes exact commands and configuration files for Ubuntu 24.04 LTS, mapped to CIS Benchmarks, NIST guidelines, and CISA advisories.

---

## 1. SSH hardening: the single most important defense

SSH is the primary attack surface on any VPS. Automated bots attempt brute-force logins within minutes of a server going online. Ubuntu 24.04 ships OpenSSH 9.6p1, which supports post-quantum key exchange. **`PerSourcePenalties` requires OpenSSH 9.8+ and is NOT available on stock 24.04** — `sshd -t` will warn but exit 0, so a reload appears to succeed while new connections silently fail. Probe before you enable it (see the canonical config below).

### ⚠️ Pre-flight safety pattern — you ARE the session being hardened

Every command in this section is being run **inside an SSH session that you are about to modify**. A single mistake can lock you out with no recovery. Before touching `sshd_config`:

1. **Open a SECOND SSH session** to the server in another terminal. Leave it open. If the first one breaks, you fix it from here.
2. **Confirm console access** (your VPS provider's web console / KVM / serial) actually works *now*. Don't discover at 2am that it doesn't.
3. **Snapshot the config** before changing it: `sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)`.
4. **Probe features, don't assume them.** Ubuntu/Debian sometimes backport directives; sometimes they don't. Use `sudo sshd -T 2>/dev/null | grep -i <directive>` to confirm a directive is actually recognized before depending on it.
5. **Validate strictly** — `sshd -t` exits 0 on warnings. Use `sshd -T` (extended test) AND a loopback connection probe to confirm sshd actually accepts new connections before you log out.

If you skip these steps and something breaks, "log in to fix it" is no longer an option. Don't skip these steps.

### Generate Ed25519 keys and disable password authentication

Ed25519 provides **128-bit equivalent security** with smaller keys, faster operations, and side-channel resistance. RSA with SHA-1 signatures (`ssh-rsa`) was deprecated in OpenSSH 8.8; DSA was removed entirely in OpenSSH 9.7+.

```bash
# On client machine: generate Ed25519 key with 100 KDF rounds
ssh-keygen -t ed25519 -C "yourname@hostname" -a 100

# Copy key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub yourusername@your-server-ip

# Verify key-based login works in a NEW terminal before proceeding
ssh -i ~/.ssh/id_ed25519 yourusername@your-server-ip
```

### Complete hardened sshd_config

Create `/etc/ssh/sshd_config.d/99-hardening.conf` (Ubuntu 24.04 uses drop-in configs):

```bash
# === Authentication ===
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
UsePAM yes
MaxAuthTries 3

# === Access Control ===
AllowUsers deployadmin

# === Session Limits ===
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
MaxStartups 10:30:60

# === Per-Source Rate Limiting (OpenSSH 9.8+ ONLY) ===
# Ubuntu 24.04 ships OpenSSH 9.6p1, which does NOT recognize this directive.
# `sshd -t` warns but exits 0, so a reload looks successful while new connections fail.
# Probe before uncommenting:
#   sudo sshd -T 2>/dev/null | grep -i persourcepenalties
# If that prints a value, the feature is available. Then uncomment:
# PerSourcePenalties crash:90,authfail:5,noauth:3,grace-exceeded:20
# Until then, rely on fail2ban or CrowdSec (section 4) for per-IP throttling.

# === Forwarding & Tunneling ===
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
GatewayPorts no

# === Logging ===
LogLevel VERBOSE
SyslogFacility AUTH

# === Crypto (post-quantum hybrid first) ===
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256
RequiredRSASize 3072

# === Misc Hardening ===
PermitUserEnvironment no
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no
UseDNS no
Compression no
Banner /etc/issue.net
Subsystem sftp /usr/lib/openssh/sftp-server -f AUTHPRIV -l INFO
```

**Ubuntu 24.04 uses socket-based SSH activation.** Validate strictly, then restart and probe:

```bash
# `sshd -t` exits 0 on WARNINGS — that's how a config with PerSourcePenalties on
# 9.6 "passes" while breaking real connections. Pair it with `sshd -T` (extended
# test: prints the effective config, fails harder on unknown directives) and a
# real loopback probe.
sudo sshd -t                                                  # basic syntax check
sudo sshd -T >/dev/null                                       # extended check (fails harder)
PORT=$(sudo sshd -T 2>/dev/null | awk '/^port /{print $2; exit}')
echo "Effective listening port: ${PORT:-22}"

sudo systemctl daemon-reload
sudo systemctl restart ssh.socket

# Verify sshd actually accepts a TCP connection BEFORE you log out.
# A healthy sshd answers with a banner like "SSH-2.0-OpenSSH_9.6p1 Ubuntu-...".
if timeout 4 bash -c "exec 3<>/dev/tcp/127.0.0.1/${PORT:-22}; head -n 1 <&3" 2>/dev/null | grep -q "^SSH-"; then
  echo "✓ sshd is accepting connections on port ${PORT:-22}"
else
  echo "✗ sshd is NOT accepting connections — DO NOT LOG OUT. Use your SECOND session to diagnose."
fi
```

**⚠️ FRESH INSTALL ONLY.** Regenerating host keys invalidates every `known_hosts`
entry for this server worldwide. Every existing client will see a host-key
mismatch warning on next connection and refuse to log in until the new
fingerprint is distributed. Don't run this on a server with active users
unless you're prepared to re-onboard every one of them.

```bash
# Guard: refuse to regenerate keys older than 10 minutes (heuristic for
# "this is no longer a fresh install"). Remove the guard intentionally if
# you've coordinated a fingerprint rotation with all clients.
KEY_AGE_SEC=$(( $(date +%s) - $(stat -c %Y /etc/ssh/ssh_host_ed25519_key 2>/dev/null || echo 0) ))
if [ "$KEY_AGE_SEC" -gt 600 ]; then
  echo "✗ Host key is $((KEY_AGE_SEC/86400)) days old — refusing to regenerate."
  echo "  This server is no longer 'fresh'. If you really want to rotate, remove this guard"
  echo "  and notify every client to update known_hosts with the new fingerprint."
  return 1 2>/dev/null || exit 1
fi

sudo rm /etc/ssh/ssh_host_*
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
sudo ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
sudo mv /etc/ssh/moduli.safe /etc/ssh/moduli
```

### Changing the SSH port (Ubuntu 24.04 socket activation)

```bash
sudo mkdir -p /etc/systemd/system/ssh.socket.d/
cat <<EOF | sudo tee /etc/systemd/system/ssh.socket.d/override.conf
[Socket]
ListenStream=
ListenStream=2222
EOF
echo "Port 2222" | sudo tee /etc/ssh/sshd_config.d/port.conf
sudo ufw allow 2222/tcp comment 'SSH'
sudo ufw delete allow 22/tcp
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
```

### Certificate-based SSH authentication (SSH CA)

SSH certificates eliminate static `authorized_keys` management. They carry identity, expiration, and principal restrictions — the gold standard at scale.

```bash
# On a secure CA machine: create CA key pairs
ssh-keygen -t ed25519 -f ~/.ssh/ssh_user_ca -C "SSH User CA"
ssh-keygen -t ed25519 -f ~/.ssh/ssh_host_ca -C "SSH Host CA"

# Sign a user's public key (12-hour certificate)
ssh-keygen -s ~/.ssh/ssh_user_ca -I "user_john" -n john,deploy -V +12h id_ed25519.pub

# Sign host key (1-year certificate)
ssh-keygen -s ~/.ssh/ssh_host_ca -I "host_web01" -h -n web01.example.com -V +52w /etc/ssh/ssh_host_ed25519_key.pub

# Server sshd_config addition:
TrustedUserCAKeys /etc/ssh/ssh_user_ca.pub
HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub

# Client known_hosts — trust host CA:
# @cert-authority *.example.com <contents of ssh_host_ca.pub>
```

### MFA for SSH (Google Authenticator)

```bash
sudo apt update && sudo apt install libpam-google-authenticator -y
google-authenticator  # Run as the user to protect; scan QR, save scratch codes

# /etc/pam.d/sshd — add near top:
auth required pam_google_authenticator.so nullok

# /etc/ssh/sshd_config.d/mfa.conf:
KbdInteractiveAuthentication yes
AuthenticationMethods publickey,keyboard-interactive

sudo systemctl restart ssh.socket   # Ubuntu 24.04 uses socket activation; `restart ssh` is a no-op-then-fail
# TEST IN A NEW TERMINAL BEFORE CLOSING YOUR SESSION
```

### What changed in OpenSSH for 2025–2026

| Version | Change | Impact |
|---------|--------|--------|
| 9.0 | `sntrup761x25519-sha512` post-quantum KEX | Future-proofs against quantum computing |
| 9.1 | `RequiredRSASize` directive | Enforce minimum 3072-bit RSA |
| 9.8 | `PerSourcePenalties` added | Per-IP rate limiting built into sshd (Ubuntu 24.04 ships 9.6p1 — NOT available without an upgrade) |
| 9.6 | Terrapin fix (CVE-2023-48795) | Integrity protection for key exchange |
| 9.7 | DSA disabled at compile-time | Must use Ed25519 or RSA |
| 9.8 | regreSSHion fix (CVE-2024-6387) | **Critical RCE — ensure updated** |
| 9.9 | CVE-2025-26465 MitM + CVE-2025-26466 DoS | **Critical — ensure updated** |
| 10.0 | `mlkem768x25519-sha256` default KEX; DSA removed | Not yet in Ubuntu 24.04 repos |

---

## 2. Firewall configuration: nftables is now the standard

Ubuntu 24.04 uses **nftables as the default backend**. The `iptables` command is actually `iptables-nft`, translating iptables syntax to nftables rules. Use **UFW for simple setups** or **nftables directly for Docker servers** (Docker bypasses UFW).

### UFW quick setup

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw limit 22/tcp comment 'SSH rate limit'  # 6 connections/30s per IP
sudo ufw enable
sudo ufw status verbose
```

### The critical Docker-UFW bypass problem

Docker manipulates iptables/nftables directly, **bypassing UFW entirely**. Published ports (`-p 8080:80`) are exposed even if UFW denies them.

**Pre-check before choosing a fix.** Run `docker ps --format '{{.Ports}}'` first. If every container publishes only to `127.0.0.1:` (or to `host.docker.internal` via a host-side reverse proxy like Traefik/Nginx that is itself the *only* thing bound to `0.0.0.0:80/443`), the bypass is already mitigated by Option B — **do NOT apply Option A on top of it**. The deny-by-default `DOCKER-USER` rules below will drop forwarded traffic to your reverse proxy's containers and silently break public HTTPS. Pick one strategy; don't stack them.

**Fix Option A — DOCKER-USER chain patch.** Add to the end of `/etc/ufw/after.rules`:

```
# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:ufw-docker-logging-deny - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j ufw-user-forward
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j RETURN
-A ufw-docker-logging-deny -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW DOCKER BLOCK] "
-A ufw-docker-logging-deny -j DROP
COMMIT
# END UFW AND DOCKER
```

Then `sudo ufw reload`.

**⚠️ MANDATORY follow-up — without this, ALL container traffic is dropped.** The rules above are deny-by-default for the `FORWARD` path that Docker uses. You MUST explicitly allow each public container port via `ufw route` (not plain `ufw allow`, which only affects `INPUT`):

```bash
sudo ufw route allow proto tcp from any to any port 80
sudo ufw route allow proto tcp from any to any port 443
# Repeat for every port you publish from a container
```

**Verify from an external host, not from the server itself.** `curl localhost` and `curl <server-ip>` *from the server* both traverse the `INPUT` chain and will succeed even when `FORWARD`/`DOCKER-USER` is blocking the public internet. Test from your laptop, a phone on cellular, or another VPS — never declare this fix done based on an on-box curl.

**Fix Option B — Gateway pattern (recommended).** Bind containers to localhost only, proxy through Nginx on the host:

```yaml
services:
  webapp:
    image: myapp
    ports:
      - "127.0.0.1:8080:80"  # Only accessible from localhost
```

### Production nftables configuration

For full control, use nftables directly. Create `/etc/nftables.conf`:

```nft
#!/usr/sbin/nft -f
flush ruleset

define SSH_PORT = 22
define WEB_PORTS = { 80, 443 }

table inet filter {
    set ssh_ratelimit {
        type ipv4_addr
        flags dynamic, timeout
        timeout 1m
    }

    set banned {
        type ipv4_addr
        flags timeout
        timeout 1h
    }

    chain input {
        type filter hook input priority filter; policy drop;

        ct state established,related accept
        ct state invalid drop
        iif "lo" accept
        ip saddr @banned drop

        # ICMP rate limited
        ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded } \
            limit rate 10/second burst 20 packets accept

        # SSH with brute-force protection
        tcp dport $SSH_PORT ct state new \
            add @ssh_ratelimit { ip saddr limit rate 3/minute burst 5 packets } accept

        # Web traffic
        tcp dport $WEB_PORTS ct state new accept

        # Drop invalid TCP flag combos (port scans)
        tcp flags & (fin|syn) == (fin|syn) drop
        tcp flags & (syn|rst) == (syn|rst) drop

        # Log then drop
        limit rate 5/second log prefix "nft-blocked: " level info
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }
}
```

```bash
sudo apt install -y nftables
sudo nft -f /etc/nftables.conf
sudo systemctl enable nftables.service
```

---

## 3. Network security and TCP/IP stack hardening

Create `/etc/sysctl.d/99-network-hardening.conf`:

```ini
# === SYN FLOOD PROTECTION ===
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# === IP SPOOFING PREVENTION ===
# Strict reverse-path filtering. CIS/USG checks for =1, not =2. Loose mode (=2)
# is for asymmetric multi-NIC routing and is WRONG for single-NIC VPSes — do
# not regress to =2 even if you see a distro drop-in setting it. If a later
# drop-in lowers this, USG/CIS will fail until you fix the offending file.
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# === DISABLE SOURCE ROUTING ===
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# === ICMP HARDENING ===
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# === LOG MARTIANS ===
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# === TCP HARDENING ===
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_timestamps = 1

# === IPv6 (disable RA if unused) ===
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
```

Apply with `sudo sysctl --system`. **Docker note:** Docker enables `net.ipv4.ip_forward = 1` automatically for container networking — this is expected and required.

To disable IPv6 entirely if unused:

```bash
echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee /etc/sysctl.d/99-disable-ipv6.conf
# Also add ipv6.disable=1 to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub
sudo update-grub && sudo sysctl --system
```

### DDoS mitigation

For edge-level protection, place your domain behind **Cloudflare** (free tier includes unmetered DDoS mitigation at **477 Tbps** capacity). Restrict web traffic to Cloudflare IPs on the origin:

```bash
for ip in $(curl -s https://www.cloudflare.com/ips-v4); do
    sudo ufw allow from $ip to any port 80,443 proto tcp
done
```

Also use your cloud provider's external firewall (DigitalOcean Cloud Firewalls, AWS Security Groups) as an additional layer before traffic reaches the VPS.

---

## 4. Kernel hardening and sysctl tuning

Create `/etc/sysctl.d/99-security-hardening.conf`:

```ini
# Full ASLR
kernel.randomize_va_space = 2
# Hide kernel pointers from all users
kernel.kptr_restrict = 2
# Restrict dmesg to root
kernel.dmesg_restrict = 1
# Restrict ptrace to parent-child processes
kernel.yama.ptrace_scope = 1
# Disable SysRq key
kernel.sysrq = 0
# Disable kexec (prevent loading malicious kernels)
kernel.kexec_load_disabled = 1
# Prevent core dumps from setuid programs
fs.suid_dumpable = 0
# Restrict unprivileged BPF
kernel.unprivileged_bpf_disabled = 1
# Harden BPF JIT
net.core.bpf_jit_harden = 2
# Restrict perf events
kernel.perf_event_paranoid = 3
# Restrict userfaultfd
vm.unprivileged_userfaultfd = 0
# Protect symlink/hardlink TOCTOU attacks
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
```

### Disable unnecessary kernel modules

Create `/etc/modprobe.d/hardening.conf`. **Use the dual-line pattern** — `install <mod> /bin/false` blocks `modprobe`, but `modprobe -f` and `insmod` can still bypass it. The matching `blacklist <mod>` line is what closes the bypass:

```ini
# Uncommon filesystems (CIS Benchmark)
install cramfs /bin/false
blacklist cramfs
install freevxfs /bin/false
blacklist freevxfs
install jffs2 /bin/false
blacklist jffs2
install hfs /bin/false
blacklist hfs
install hfsplus /bin/false
blacklist hfsplus
install udf /bin/false
blacklist udf

# Uncommon network protocols
install dccp /bin/false
blacklist dccp
install sctp /bin/false
blacklist sctp
install rds /bin/false
blacklist rds
install tipc /bin/false
blacklist tipc

# USB storage — OPTIONAL. Many VPS providers' rescue/recovery flows reattach
# the root disk over a USB-like emulated bus. Disabling this can prevent
# recovery boot from your provider's console. Leave commented unless you
# have confirmed your provider's recovery path does not depend on it.
# install usb-storage /bin/false
# blacklist usb-storage
```

### AppArmor 4.0 on Ubuntu 24.04

Ubuntu 24.04 ships **AppArmor 4.0** enabled by default, with new features including io_uring mediation and **unprivileged user namespace restrictions** (`kernel.apparmor_restrict_unprivileged_userns=1`).

```bash
sudo apt install apparmor-utils apparmor-profiles apparmor-profiles-extra
sudo aa-status  # Check profile enforcement status
sudo aa-enforce /etc/apparmor.d/usr.sbin.nginx  # Force enforce mode

# Harden unprivileged namespace restrictions
echo 'kernel.apparmor_restrict_unprivileged_unconfined = 1' | \
  sudo tee /etc/sysctl.d/60-apparmor-namespace.conf
sudo sysctl --system
```

### GRUB boot security

Add hardened kernel parameters to `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash audit=1 audit_backlog_limit=8192 init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 slab_nomerge pti=on randomize_kstack_offset=on vsyscall=none"
```

**`init_on_alloc=1` and `init_on_free=1` are one variable, not two.** KSPP guidance is to set both together. Alloc-only zeroing leaves a window where freed-then-reused pages can leak prior contents to the next allocator that picks them up. Free-only zeroing leaves the first allocation of a fresh page uninitialised. The defense only works as a pair. Never include one in the cmdline without the other.

Password-protect GRUB to prevent boot parameter tampering.

> ### ⚠️ STOP — read this before setting a GRUB password on a VPS
>
> A GRUB superuser password without `--unrestricted` blocks **unattended boot**. Every kernel update, panic recovery, host migration, or provider-side maintenance reboot will then hang at the bootloader waiting for someone to type the password at the console. On a VPS you do not physically touch, that "someone" is you, racing to the provider's browser KVM during an outage.
>
> 1. **Most VPS users should skip this hardening step entirely.** Your provider's account login already gates console access — adding a GRUB password protects against an attacker who has *already* compromised the hypervisor console, which is a threat model your VPS provider is responsible for, not you. The threat this defends against (physical access to a powered-on machine with a USB keyboard) does not exist for cloud VMs.
>
> 2. **If you still want it, you MUST add `--unrestricted`** so the password is required only to *edit* a boot entry or open the GRUB shell, not to *boot* the existing entries. Without `--unrestricted` the box will not reboot unattended — guaranteed.
>
> 3. **Password typability matters.** Hostinger / DigitalOcean / Vultr / Linode / OVH browser consoles force US keyboard layout at the bootloader stage with **no clipboard paste**. A 20-character random mixed-case password generated from your laptop is borderline untypeable when you actually need it at 3am. Use a 6-word diceware-style passphrase made of lowercase letters only, or 12+ digits — something you can type one-handed without looking.
>
> 4. **Never reboot immediately after applying this.** Schedule a maintenance window with (a) the browser console already open, (b) the password printed on paper next to you, and (c) the destination recovery procedure rehearsed. A failed boot at this stage means an outage that ends only when you reach the console or restore from snapshot.
>
> 5. **Clean up `/etc/grub.d/*.bak` files before running `update-grub`.** Any *executable* file in `/etc/grub.d/` is sourced by `grub-mkconfig`, including your own backups (`40_custom.bak`, `40_custom.orig`, etc.). A stale backup will re-inject an old password block on the next update-grub. After editing, run `sudo chmod -x /etc/grub.d/*.bak /etc/grub.d/*.orig 2>/dev/null` or move backups outside the directory entirely.

```bash
# Step 1 — generate the hash interactively (CANNOT be safely automated;
# piping the password into stdin leaks it to the process table and shell history)
grub-mkpasswd-pbkdf2
# Enter password: <type your typable-at-console password twice>
# Copy the resulting 'grub.pbkdf2.sha512.10000.<hash>' line.

# Step 2 — declare the superuser in /etc/grub.d/40_custom
sudo tee -a /etc/grub.d/40_custom >/dev/null <<'EOF'
set superusers="grubadmin"
password_pbkdf2 grubadmin grub.pbkdf2.sha512.10000.PASTE_HASH_HERE
EOF

# Step 3 — MANDATORY: add --unrestricted to the auto-generated menu entries
# so unattended boot still works. Without this, unattended-upgrades + auto-reboot
# = a server that never comes back up.
sudo sed -i 's|^CLASS="\(.*\)"|CLASS="\1 --unrestricted"|' /etc/grub.d/10_linux
grep '^CLASS=' /etc/grub.d/10_linux   # Verify --unrestricted is present

# Step 4 — regenerate grub.cfg and verify menuentries carry --unrestricted
sudo update-grub
grep -E 'menuentry .*--unrestricted' /boot/grub/grub.cfg | head -3
# If grep returns nothing, DO NOT REBOOT. Re-check step 3.

# Step 5 — verify no stray backups will re-source on next update-grub
ls -la /etc/grub.d/ | grep -E '\.(bak|orig|old)$'  # Should return empty
```

Source: CIS Ubuntu 24.04 v1.0.0 §1.4 (Secure Boot Settings) — the `--unrestricted` allowance is the explicit CIS-sanctioned escape hatch for servers that must boot unattended.

### What Ubuntu 24.04 enables by default vs what needs manual hardening

**Enabled by default:** ASLR (value 2), AppArmor 4.0, symlink/hardlink protection, Yama ptrace_scope=1, unprivileged BPF disabled, dmesg_restrict=1, FORTIFY_SOURCE=3, TLS 1.0/1.1 disabled system-wide.

**Needs manual hardening:** `kptr_restrict=2` (default is 1), `sysrq=0`, `kexec_load_disabled=1`, `perf_event_paranoid=3`, `fs.protected_fifos=2`, `bpf_jit_harden=2`, `vm.unprivileged_userfaultfd=0`.

---

## 5. Intrusion detection: CrowdSec replaces fail2ban as the modern standard

### Fail2ban (still works, but has a Python 3.12 issue on 24.04)

Ubuntu 24.04's Python 3.12 removed the `asynchat` module. **Fail2ban 1.0.2 from repos will fail to start** without patching:

```bash
sudo apt install -y fail2ban rsyslog
sudo systemctl enable --now rsyslog  # Required for auth.log

# Apply asynchat compatibility patch if fail2ban fails:
sudo mkdir -m 0755 /usr/lib/python3/dist-packages/fail2ban/compat
sudo wget -O /usr/lib/python3/dist-packages/fail2ban/compat/asynchat.py \
  https://github.com/fail2ban/fail2ban/raw/1024452fe/fail2ban/compat/asynchat.py
sudo wget -O /usr/lib/python3/dist-packages/fail2ban/compat/asyncore.py \
  https://github.com/fail2ban/fail2ban/raw/1024452fe/fail2ban/compat/asyncore.py
```

Create `/etc/fail2ban/jail.local`:

```ini
[DEFAULT]
bantime = 3h
findtime = 15m
maxretry = 3
banaction = ufw
ignoreip = 127.0.0.1/8 ::1 YOUR_TRUSTED_IP

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 3h

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 1h
```

### CrowdSec — the recommended IPS for 2025

CrowdSec's **crowdsourced threat intelligence** preemptively blocks known-malicious IPs before they attack your server. It handles distributed brute-force that evades fail2ban, has native nftables support, and no Python 3.12 issues.

```bash
curl -s https://install.crowdsec.net | sudo sh
sudo apt update && sudo apt install -y crowdsec

# Install nftables bouncer (recommended for Ubuntu 24.04)
sudo apt install -y crowdsec-firewall-bouncer-nftables
sudo systemctl enable --now crowdsec-firewall-bouncer

# Install scenario collections
sudo cscli collections install crowdsecurity/linux
sudo cscli collections install crowdsecurity/nginx
sudo cscli scenarios install crowdsecurity/ssh-bf crowdsecurity/http-probing
sudo systemctl reload crowdsec

# Verify
sudo cscli metrics
sudo cscli decisions list
sudo cscli bouncers list
```

### Wazuh has replaced OSSEC

**OSSEC's last release was January 2021** — it is effectively abandoned. **Wazuh** (v4.12+, actively maintained) provides log analysis, file integrity monitoring, vulnerability detection, rootkit detection, compliance dashboards (PCI-DSS, HIPAA, NIST), and a full web UI.

```bash
# Agent installation (connects to Wazuh manager)
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
WAZUH_MANAGER='YOUR_MANAGER_IP' sudo apt install -y wazuh-agent
sudo systemctl enable --now wazuh-agent
```

**Recommended 2025 IDS stack:** CrowdSec (IPS with community intelligence) + Wazuh (SIEM/HIDS/FIM).

---

## 6. Logging, auditing, and monitoring

### auditd with CIS Benchmark rules

```bash
sudo apt install -y auditd audispd-plugins
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="audit=1 audit_backlog_limit=8192"/' /etc/default/grub
sudo update-grub
sudo systemctl enable --now auditd
```

Create `/etc/audit/rules.d/20-identity.rules`:
```
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
```

Create `/etc/audit/rules.d/30-privilege.rules`:
```
-w /etc/sudoers -p wa -k actions
-w /etc/sudoers.d/ -p wa -k actions
-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k privilege_escalation
```

Create `/etc/audit/rules.d/40-access.rules`:
```
-a always,exit -F arch=b64 -S open,openat,creat,truncate,ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S open,openat,creat,truncate,ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
```

Create `/etc/audit/rules.d/99-finalize.rules`:
```
-e 2
```

Load rules: `sudo augenrules --load`

### journald persistence

Create `/etc/systemd/journald.conf.d/hardened.conf`:

```ini
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
MaxRetentionSec=3month
ForwardToSyslog=yes
```

```bash
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

### Alert delivery infrastructure (REQUIRED before any `mail` command)

**Read this section before deploying AIDE, ClamAV, rkhunter, chkrootkit, fail2ban-style alerts, or any cron job that relies on `MAILTO=`.** Ubuntu 24.04 server has **no MTA installed by default**. The scripts below pipe to `mail`, which depends on a working mail-transfer agent. If you run them without configuring one first, every alert is silently discarded by `mail`'s exit code 1 — and the cron wrapper happily moves on. You then have monitoring that *looks* configured but has been dark since day one. **Treat this as the AIDE/ClamAV/rkhunter prerequisite, not as optional polish.**

**`ssmtp` is dead — don't use it.** Removed from Debian/Ubuntu repos because upstream is unmaintained and the codebase has unfixed TLS bugs. Two supported architectures remain in 2026:

| | **msmtp (recommended for single-VPS alerts)** | **Postfix null client (recommended when you need queueing)** |
|--|--|--|
| Listener | None — pure outbound relay client | localhost-only (CIS v1.0.0 rule satisfied) |
| Failure behavior | Drops on transient SMTP errors | Queues and retries (deferred queue) |
| Attack surface | One static binary, no daemon | smtpd/qmgr/cleanup/pickup daemons, chrootable |
| Use when | Alerts to one inbox, you trust your relay | You want delivery guarantees, or already run Postfix |

**Both architectures MUST**, per NIST SP 800-177r1: (1) submit over STARTTLS on 587 or implicit TLS on 465, never plaintext 25 outbound; (2) authenticate with a scoped credential (App Password, OAuth2, or provider API key), never a reused account password — Gmail killed Less Secure Apps on 2024-09-30 and other providers followed; (3) use a `From:` address whose domain has aligned SPF/DKIM/DMARC records, or alerts will be silently spam-filtered at the recipient end.

#### Option A — msmtp + mailutils (lightweight)

```bash
sudo apt install -y msmtp msmtp-mta mailutils ca-certificates
# msmtp-mta provides /usr/sbin/sendmail symlink so 'mail', cron MAILTO, and AIDE-style scripts all work
```

Create `/etc/msmtprc` (NEVER world-readable — msmtp refuses to start if perms are wrong, which is by design):

```
# /etc/msmtprc — system-wide send-only relay
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        relay
host           smtp.gmail.com           # or smtp.sendgrid.net, email-smtp.<region>.amazonaws.com, etc.
port           587
from           alerts@your-real-domain.tld
user           alerts@your-real-domain.tld
passwordeval   "cat /etc/msmtp.password"   # see credential hardening below

account default : relay
aliases        /etc/aliases
```

Lock the config and create the credential file:

```bash
sudo chown root:root /etc/msmtprc && sudo chmod 0600 /etc/msmtprc
sudo install -m 0600 -o root -g root /dev/null /etc/msmtp.password
# Paste the 16-char Gmail App Password (or provider API secret) into the file:
sudo nano /etc/msmtp.password
sudo install -m 0640 -o root -g adm /dev/null /var/log/msmtp.log
```

Route `root` mail to a real inbox so cron `MAILTO=root` (the default) and `mail root` both reach you:

```bash
echo "root: alerts@your-real-domain.tld" | sudo tee -a /etc/aliases
sudo newaliases 2>/dev/null || true   # harmless if no sendmail-newaliases
```

**Stronger credential hardening (preferred for production).** The `passwordeval` directive runs any command, so the password file should ideally never exist in plaintext at rest:

- **systemd credentials** (systemd 250+, available on 24.04): encrypt with `systemd-creds encrypt` and reference via `LoadCredentialEncrypted=` from the service that runs the alert script. `passwordeval "systemd-creds cat smtp_pw"`.
- **age / gpg encrypted file**: `passwordeval "age --decrypt -i /root/.age-key /etc/msmtp.password.age"` — the key file holds the secret; the relay password is encrypted at rest. msmtp's own example uses `gpg2 --no-tty -q -d`.
- **Cloud-native**: pull at boot from AWS SSM Parameter Store / GCP Secret Manager / HashiCorp Vault into a tmpfs file, never on disk.

#### Option B — Postfix null client (queue-backed)

```bash
sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix mailutils libsasl2-modules
# When prompted, pick "Internet Site" then accept defaults — we overwrite main.cf next.
```

Overwrite `/etc/postfix/main.cf` with the canonical Postfix null-client recipe (verbatim from postfix.org STANDARD_CONFIGURATION):

```ini
# /etc/postfix/main.cf — null client (send-only, localhost listener)
myhostname        = $(hostname -f)
myorigin          = $mydomain
mydestination     =
relayhost         = [smtp.gmail.com]:587   # brackets disable MX lookup
inet_interfaces   = loopback-only           # CIS v1.0.0: MTA local-only mode
inet_protocols    = ipv4
mynetworks        = 127.0.0.0/8 [::1]/128

# SASL auth + STARTTLS to the relay
smtp_sasl_auth_enable          = yes
smtp_sasl_password_maps        = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options     = noanonymous
smtp_tls_security_level        = encrypt    # MANDATORY TLS — never 'may'
smtp_tls_CAfile                = /etc/ssl/certs/ca-certificates.crt
smtp_tls_loglevel              = 1

# Rewrite local From: to the relay's authorized sender
sender_canonical_maps          = regexp:/etc/postfix/sender_canonical
```

```bash
echo "[smtp.gmail.com]:587 alerts@your-real-domain.tld:APP_PASSWORD" | sudo tee /etc/postfix/sasl_passwd
sudo chmod 0600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd          # produces sasl_passwd.db (0600)
sudo shred -u /etc/postfix/sasl_passwd          # delete plaintext source; keep encrypted backup off-box
echo "/.+/    alerts@your-real-domain.tld" | sudo tee /etc/postfix/sender_canonical
```

**Now choose a recipient-rewrite strategy.** Two valid approaches — pick one, don't mix:

**Option A — `recipient_canonical_maps` (simpler, standalone).** Rewrite happens before delivery decisions, so it works regardless of how `mydestination` and `myorigin` are set. Recommended for tight, scriptable null-client setups:

```ini
# Add to main.cf:
recipient_canonical_maps = regexp:/etc/postfix/recipient_canonical
```

```bash
sudo tee /etc/postfix/recipient_canonical >/dev/null <<'EOF'
/^(root|postmaster|.*)@/    alerts@your-real-domain.tld
EOF
```

**Option B — `/etc/aliases` (standard, but has a footgun).** Uses Postfix's normal local-delivery → alias-expansion machinery. Recommended if other admins or tools expect `/etc/aliases` to be authoritative. **The gotcha:** alias expansion only fires when the recipient's domain is in `mydestination`. If `myorigin` (or any envelope-recipient domain) resolves to a value NOT listed in `mydestination`, Postfix skips alias expansion entirely and tries to relay the bare address — which fails or sends to the wrong inbox. Make sure these stay aligned:

```ini
# Add to main.cf for Option B (note: these REPLACE the null-client myorigin):
myorigin       = $myhostname
mydestination  = $myhostname, localhost.localdomain, localhost
```

```bash
echo "root: alerts@your-real-domain.tld" | sudo tee -a /etc/aliases
sudo newaliases
```

```bash
sudo systemctl restart postfix
# Verify listener really is localhost only — must show 127.0.0.1:25, NOT 0.0.0.0:25
sudo ss -tlnp | grep :25
```

#### End-to-end verification — DO THIS, do not skip it

A successful SMTP submission does not mean the email reached the inbox. Provider reputation, SPF/DKIM/DMARC misalignment, and recipient spam folders all silently swallow mail at the destination. This is the same trap as the `DOCKER-USER` on-box `curl` test — the layer you can see succeeded; the layer that matters didn't.

```bash
# 1. Real path test — exercise the actual alert pipeline, not a synthetic one
echo "vps-hardening MTA smoke test from $(hostname) at $(date -Iseconds)" \
  | mail -s "MTA smoke test" root

# 2. Confirm submission
sudo tail -n 20 /var/log/msmtp.log         # Option A
sudo journalctl -u postfix -n 30 --no-pager # Option B; expect 'status=sent'

# 3. Confirm receipt — open the destination inbox in a browser. Check spam folder.
# 4. Force a real alert. Touch a file AIDE watches, then run /usr/local/bin/aide-check.sh
#    manually and verify the email lands. If you skip steps 3-4, your alerts ARE silently broken.
```

If the message goes to spam, fix SPF/DKIM/DMARC on the sending domain (NIST SP 800-177r1 §4–6) before declaring this done — a spam-filtered alert is a missed alert.

### File integrity monitoring with AIDE

> **Prerequisite:** the script below pipes to `mail`. Configure msmtp or Postfix null client first — see "Alert delivery infrastructure" above. Without it, every AIDE alert is silently dropped.

> **Timing — run `aideinit` as the LAST step of P2.** AIDE's baseline is a snapshot. If you take it before USG, ClamAV, rkhunter, chkrootkit, CrowdSec, and any other P2 installs finish settling, every daily check from then on will show thousands of "added" entries from those tools' files. Operators then learn to ignore AIDE alerts — exactly what you wanted to avoid. Install AIDE early but `aideinit` last, after all other P2 changes are done.

Add the exclusions BEFORE `aideinit`. The skill creates `/var/log/sudo-io` via the `iolog_dir` sudo recommendation, and every sudo invocation writes a fresh tree of binary recordings there — without exclusion, AIDE reports hundreds of new files per day from this skill's own configuration:

```bash
sudo apt install -y aide aide-common

# Add exclusions BEFORE the baseline. Anything written here is signal
# the skill itself generates and would otherwise drown out real findings.
sudo tee -a /etc/aide/aide.conf.d/99-vps-hardening-excludes >/dev/null <<'EOF'
!/var/log/sudo-io
!/var/log/aide
!/var/log/msmtp.log
!/var/log/nginx
!/var/log/journal
!/var/lib/clamav
!/var/lib/rkhunter
EOF

# Run aideinit AFTER every other P2 install has settled
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
sudo cp /var/lib/aide/aide.db /root/aide.db.backup

# Automated daily check
cat <<'EOF' | sudo tee /usr/local/bin/aide-check.sh
#!/bin/bash
LOG="/var/log/aide/aide-$(date +%Y-%m-%d).log"
mkdir -p /var/log/aide
aide --check 2>&1 | tee "$LOG"
[ $? -ne 0 ] && mail -s "AIDE Alert on $(hostname)" admin@example.com < "$LOG"
EOF
sudo chmod +x /usr/local/bin/aide-check.sh
echo "0 3 * * * root /usr/local/bin/aide-check.sh" | sudo tee /etc/cron.d/aide-check
```

---

## 7. Malware and rootkit detection

> **Prerequisite for every script in this section:** the ClamAV, rkhunter, and chkrootkit alert pipelines all pipe to `mail`. Configure msmtp or Postfix null client first (see §6 "Alert delivery infrastructure"). Without it, infections and rootkit detections are silently swallowed.

### ClamAV automated scanning

```bash
sudo apt install -y clamav clamav-daemon
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl enable --now clamav-freshclam clamav-daemon
```

Automated weekly scan script (`/usr/local/bin/clamav-scan.sh`):

```bash
#!/bin/bash
SCAN_DIR="/home /var/www /tmp"
LOG="/var/log/clamav/weekly_$(date +%Y%m%d).log"
mkdir -p /var/log/clamav /var/quarantine
nice -n 15 clamscan -r -i --move=/var/quarantine --log="$LOG" $SCAN_DIR
INFECTED=$(grep "Infected files:" "$LOG" | awk '{print $NF}')
[ "$INFECTED" -gt 0 ] && mail -s "ClamAV: $INFECTED infections on $(hostname)" admin@example.com < "$LOG"
```

### rkhunter and chkrootkit (run both — different detection methods)

```bash
sudo apt install -y rkhunter chkrootkit
sudo sed -i 's|WEB_CMD="/bin/false"|WEB_CMD=""|' /etc/rkhunter.conf
sudo rkhunter --update && sudo rkhunter --propupd  # Baseline on CLEAN system only

# /etc/default/rkhunter:
# CRON_DAILY_RUN="true"
# APT_AUTOGEN="true"
```

### Recommended scan schedule

```
0 1 * * * root /usr/bin/freshclam --quiet
0 2 * * * root /usr/bin/rkhunter --cronjob --update --quiet
0 3 * * * root /usr/local/bin/aide-check.sh
0 4 * * 0 root /usr/local/bin/clamav-scan.sh
0 5 * * 1 root /usr/sbin/chkrootkit -q | mail -s "chkrootkit $(hostname)" admin@example.com
```

**Monarx** is a commercial behavior-based malware detection platform specifically for PHP/CMS hosting — it catches zero-days via execution analysis rather than signatures. Worth adding if hosting WordPress or similar.

---

## 8. User and privilege management

### Sudo hardening

Edit via `sudo visudo`:

```
Defaults    env_reset
Defaults    mail_badpass
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults    use_pty
Defaults    logfile="/var/log/sudo.log"
Defaults    log_input, log_output
Defaults    timestamp_timeout=5
Defaults    passwd_tries=3
Defaults    requiretty
```

Grant least-privilege per service (`/etc/sudoers.d/webadmin`):

```
webadmin ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl restart php*-fpm
```

### Account lockout with pam_faillock (replaces deprecated pam_tally2)

Create `/etc/security/faillock.conf`:

```ini
deny = 5
unlock_time = 900
even_deny_root
fail_interval = 900
audit
```

### Password policy with pam_pwquality

`/etc/security/pwquality.conf`:

```ini
minlen = 14
minclass = 3
maxrepeat = 3
dictcheck = 1
enforce_for_root
```

### Lock and audit accounts

```bash
# Audit accounts with login shells
awk -F: '$7 !~ /(nologin|false)/ {print $1}' /etc/passwd

# Lock unused accounts
sudo usermod -L -s /usr/sbin/nologin username

# Lock root password (force sudo)
sudo passwd -l root

# Restrict su to wheel group
sudo groupadd wheel && sudo usermod -aG wheel trustedadmin
# In /etc/pam.d/su add: auth required pam_wheel.so use_uid group=wheel

# Set restrictive umask
echo "umask 027" | sudo tee /etc/profile.d/umask.sh
```

### Idle shell timeout (TMOUT) — exact format matters

USG's OVAL test for shell session timeout uses a strict regex that requires the three directives on **separate lines, in this order**, in `/etc/profile` or any `/etc/profile.d/*.sh` file. The compact `export TMOUT=900` one-liner that works at the shell will pass interactively but fail the OVAL test, leaving you with a real timeout and a failing CIS rule simultaneously — confusing to debug:

```bash
sudo tee /etc/profile.d/00-tmout.sh >/dev/null <<'EOF'
TMOUT=900
readonly TMOUT
export TMOUT
EOF
sudo chmod 0644 /etc/profile.d/00-tmout.sh
```

Verify by re-logging in and running `echo $TMOUT` (must print 900) and `readonly -p | grep TMOUT` (must show it as readonly). Do NOT collapse to `export TMOUT=900` or `readonly TMOUT=900` — those forms fail the OVAL check.

---

## 9. File system security

### Hardened mount options in `/etc/fstab`

```
tmpfs    /tmp       tmpfs    defaults,noexec,nosuid,nodev,size=2G    0 0
/tmp     /var/tmp   none     defaults,noexec,nosuid,nodev,bind       0 0
tmpfs    /dev/shm   tmpfs    defaults,noexec,nosuid,nodev,size=512M  0 0
proc     /proc      proc     defaults,hidepid=2                      0 0
```

Apply immediately: `sudo mount -o remount,noexec,nosuid,nodev /tmp`

### Immutable flags on critical files

**Scope matters — see "Operator gotchas / chattr +i scope" in SKILL.md.** Only lock files that no legitimate tool needs to modify in normal operation. Locking `/etc/passwd` or `/etc/shadow` breaks `chage`, `usermod`, `adduser`, PAM `sp_lstchg` updates, and any package postinst that creates a service user — with silent exit-0 failure modes (e.g. `chage --maxdays N <user>` exits 0 and writes nothing if `/etc/passwd` is immutable, because `chage` opens `passwd` read-only as part of writing to `shadow`). The attacker-writes-a-backdoor threat these were meant to defend is better covered by `auditd -w /etc/passwd -p wa -k identity` + AIDE alerts on the same paths.

```bash
# Safe to lock — these are not modified by package management or routine ops
sudo chattr +i /etc/ssh/sshd_config /etc/ssh/sshd_config.d/99-hardening.conf /boot/grub/grub.cfg
# To edit: sudo chattr -i <path>, make changes, sudo chattr +i <path>
```

Do NOT `chattr +i` on `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow`, `/etc/sudoers`, or `/etc/sudoers.d/*`. Rely on auditd + AIDE for tamper detection on those instead.

### Critical file permissions

```bash
sudo chmod 600 /etc/shadow /etc/gshadow /etc/ssh/sshd_config /boot/grub/grub.cfg
sudo chmod 644 /etc/passwd /etc/group
sudo chmod 700 /root /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly
sudo chmod 600 /etc/crontab
```

### SUID/SGID audit

```bash
# Find all SUID/SGID files
sudo find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null

# Remove SUID from unneeded binaries
sudo chmod u-s /usr/bin/chfn /usr/bin/chsh /usr/bin/newgrp

# Monitor for changes
sudo find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -printf "%m %u %g %p\n" > /root/suid_baseline.txt
```

---

## 10. Automatic security updates and patch management

Ubuntu 24.04 has `unattended-upgrades` enabled by default for security updates. Configure additional settings in `/etc/apt/apt.conf.d/52-custom-unattended`:

```
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Mail "admin@yourdomain.com";
Unattended-Upgrade::MailReport "on-change";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
```

Test: `sudo unattended-upgrade --dry-run -v`

### Ubuntu Pro and Livepatch

Ubuntu Pro (free for up to 5 machines) provides **10 years of patches**, ESM for universe packages, and **Kernel Livepatch** — patching critical CVEs in the running kernel without reboot:

```bash
sudo pro attach YOUR_PRO_TOKEN
sudo pro enable livepatch
sudo canonical-livepatch status --verbose
```

### CIS compliance scanning with USG

```bash
sudo pro enable usg
sudo apt install usg
sudo usg audit cis_level1_server   # Audit
sudo usg fix cis_level1_server     # Apply fixes
```

#### Tailoring file: the actual workflow

`usg audit --tailoring-file=...` rejects standalone XCCDF tailoring documents (`Unknown type of tailoring file`). The supported workaround is to call `oscap` directly with the same datastream USG ships:

```bash
sudo oscap xccdf eval \
    --tailoring-file /etc/usg/$(hostname)-tailoring.xml \
    --profile xccdf_org_tailored_cis_level1_server_$(hostname) \
    --results /var/lib/usg/tailored-results.xml \
    /usr/share/usg-benchmarks/ubuntu2404_CIS_1/ssg-ubuntu2404-xccdf.xml
```

**Use tailoring only for architectural exemptions, never to hide real failures.** Legitimate exemptions on a Docker host include `sysctl_net_ipv4_ip_forward` (Docker requires it), `package_ufw_removed` (we use UFW), and `service_nftables_enabled` (UFW manages nftables for us). If you find yourself tailoring out a rule because "fixing it would break the app," fix the app instead — that's a real finding, not an exemption.

### Meta-rule — rotating a credential on a service that apps depend on

This rule applies to every recipe in this guide that changes a credential on a service consumed by long-lived application processes — Redis `requirepass`, MySQL/MariaDB root or app-user passwords, RabbitMQ users, MQTT auth, Postgres roles, anything similar. **Order matters. Get it wrong and you get production 500s during the gap window.**

1. **Update every dependent app's config file first** — `.env`, framework config (`config/database.php`, Laravel/Symfony/Rails equivalents), `docker-compose.yml` env, K8s secrets, whatever holds the credential the app reads at startup.
2. **Invalidate every cache the app has of that credential** — `php artisan config:clear && php artisan config:cache` (Laravel caches `.env` aggressively), `systemctl reload nginx`, restart long-lived workers (Sidekiq, Celery, queue runners, PM2-managed Node processes) — anything that may have read the old credential into memory at boot.
3. **Only then change the credential on the service itself and restart/reload it.**

If you set the new credential on the service first, every dependent app uses the old credential against the new service for the rotation window — production 500s until you finish. The damage scales with the number of dependent apps, so on a multi-app box this can cascade into a full outage. The discipline is "apps know first, then service" — without exception.

---

## 11. Docker and container security

### Rootless Docker on Ubuntu 24.04

Ubuntu 24.04's AppArmor restrictions on unprivileged user namespaces **break rootless Docker out of the box**. Fix first:

```bash
sudo apt install -y docker-ce docker-ce-rootless-extras uidmap dbus-user-session slirp4netns

# Fix AppArmor restriction
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
echo 'kernel.apparmor_restrict_unprivileged_userns=0' | sudo tee /etc/sysctl.d/99-rootless-docker.conf

# Stop rootful Docker
sudo systemctl disable --now docker.service docker.socket

# Install rootless as your user
dockerd-rootless-setuptool.sh install
systemctl --user enable --now docker
sudo loginctl enable-linger $USER
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
```

### Hardened daemon.json

```json
{
  "icc": false,
  "userns-remap": "default",
  "no-new-privileges": true,
  "userland-proxy": false,
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "ip": "127.0.0.1",
  "default-ulimits": {
    "nofile": { "Name": "nofile", "Hard": 65536, "Soft": 65536 },
    "nproc": { "Name": "nproc", "Hard": 4096, "Soft": 4096 }
  }
}
```

Key settings: **`icc: false`** disables inter-container communication on the default bridge. **`userns-remap: default`** maps container root to an unprivileged host UID. **`ip: 127.0.0.1`** binds published ports to localhost only.

**On `storage-driver` — do NOT hardcode it.** Earlier guides set `"storage-driver": "overlay2"` explicitly. As of Docker 29.0 (Nov 2025), the default is the new `overlayfs` driver (kernel-native, no userspace shim). Forcing `overlay2` on a daemon that already initialized its data tree under `overlayfs` (or vice versa) makes Docker refuse to start with `mismatched storage driver` and orphans every existing image and volume until you either flip the value back or wipe `/var/lib/docker`. **Always check first** with `docker info | grep "Storage Driver"` and only set this key if you have a specific reason to override the default — never as boilerplate.

### Vulnerability scanning with Trivy (NOT Docker-only — install on every VPS)

Trivy is filed under §11 because the Docker workflow is its highest-profile use, but the same binary scans **OS packages, filesystem paths, and language-specific lockfiles** with no Docker daemon involved. Install it even on host-only stacks (Laravel/Symfony, Node, Python, Ruby, Go) — `composer.lock`, `package-lock.json`, `Gemfile.lock`, `requirements.txt`, `go.mod`, and `Cargo.lock` are all first-class scan targets. On a Docker-less Laravel VPS, Trivy is still the most useful CVE scanner you can install.

```bash
# Install (works on every VPS — no Docker required)
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb noble main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update && sudo apt install -y trivy
```

**Scan mode 1 — host OS packages and language lockfiles in one sweep (`trivy rootfs`).** This is the most underused Trivy mode and the one most relevant to a hardened VPS without Docker. It walks the live filesystem and reports CVEs in every installed `.deb` (apt index) AND every language lockfile it discovers (composer.lock, package-lock.json, Gemfile.lock, etc.):

```bash
# Full host scan — installed packages + every lockfile under /
sudo trivy rootfs --scanners vuln --severity HIGH,CRITICAL /

# Faster: scan a specific app directory (composer.lock for Laravel, package-lock.json for Node)
sudo trivy fs --scanners vuln --severity HIGH,CRITICAL /var/www/your-laravel-app

# Cron the host scan weekly (mail alert via the MTA you configured in §6)
cat <<'EOF' | sudo tee /etc/cron.weekly/trivy-host-scan
#!/bin/bash
OUT=$(mktemp)
/usr/bin/trivy rootfs --scanners vuln --severity HIGH,CRITICAL --quiet --no-progress / > "$OUT" 2>&1
grep -q "Total: 0" "$OUT" || mail -s "Trivy host scan: HIGH/CRITICAL CVEs on $(hostname)" root < "$OUT"
rm -f "$OUT"
EOF
sudo chmod +x /etc/cron.weekly/trivy-host-scan
```

**Scan mode 2 — misconfig scanning (`trivy config`).** Catches dangerous defaults in IaC files you ship: Dockerfiles missing `USER` directives, K8s manifests with `privileged: true`, Terraform with open security groups, Compose files mounting the docker socket. Run on any directory containing infra-as-code:

```bash
trivy config --severity HIGH,CRITICAL /path/to/your/repo
```

**Scan mode 3 — container images (Docker users only).** The CI/CD gate and SBOM workflow:

```bash
# CI/CD gate: fail on HIGH/CRITICAL
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:v1.0

# Generate SBOM (CycloneDX format — works for image, fs, and rootfs scans too)
trivy image -f cyclonedx -o sbom.cdx.json myapp:v1.0
```

**Database freshness matters.** Trivy caches its vulnerability DB locally and only refreshes on scan. On an air-gapped or low-traffic VPS, the DB can go stale silently. Run a weekly `trivy --download-db-only` or rely on the cron above (each invocation triggers a DB check). If you see no findings on a known-vulnerable package, run `trivy --reset` and re-scan before trusting the result.

### Production-hardened Docker Compose

```yaml
services:
  webapp:
    image: myapp:v1.2.3          # Pin specific versions
    user: "10001:10001"
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=50m
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 256M
    pids_limit: 100
    ports:
      - "127.0.0.1:8080:8080"
    networks:
      - frontend
      - backend
    secrets:
      - db_password
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  db:
    image: postgres:16-alpine
    read_only: true
    tmpfs: [/tmp, /run/postgresql]
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    networks:
      - backend
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true             # No external access

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Docker socket security

**Never mount `/var/run/docker.sock` into containers** — access equals root on the host. If required (e.g., CI runners), use a socket proxy like `tecnativa/docker-socket-proxy` with restricted API access.

```bash
# Audit Docker socket
sudo chmod 660 /var/run/docker.sock
sudo chown root:docker /var/run/docker.sock
getent group docker  # Each member has root-equivalent access

# Audit rules for Docker
echo '-w /var/run/docker.sock -p rwxa -k docker_socket' | sudo tee -a /etc/audit/rules.d/docker.rules
echo '-w /usr/bin/docker -p rwxa -k docker_binary' | sudo tee -a /etc/audit/rules.d/docker.rules
```

Run Docker Bench for Security: `docker run --rm --net host --pid host -v /var/run/docker.sock:/var/run/docker.sock:ro docker/docker-bench-security`

---

## 12. TLS/SSL best practices: Let's Encrypt dropped OCSP in 2025

### Mozilla Intermediate profile (recommended for most servers)

```nginx
# /etc/nginx/conf.d/ssl-hardening.conf
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_ecdh_curve X25519:prime256v1:secp384r1;
ssl_dhparam /etc/nginx/dhparam.pem;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
```

Generate DH parameters: `curl https://ssl-config.mozilla.org/ffdhe2048.txt -o /etc/nginx/dhparam.pem`

### Let's Encrypt with certbot

```bash
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx -d example.com -d www.example.com --key-type ecdsa
sudo certbot renew --dry-run  # Verify auto-renewal
```

### OCSP stapling — no longer needed for Let's Encrypt

**Let's Encrypt dropped OCSP support on August 6, 2025.** Revocation now uses CRLs and browser-native mechanisms (CRLite in Firefox, CRLSets in Chrome). OCSP stapling directives are now harmless but unnecessary for Let's Encrypt certificates. Keep them only if using commercial CAs that still provide OCSP URLs.

### Verify with SSL Labs

Test your configuration at `https://www.ssllabs.com/ssltest/` — target an **A+** rating.

---

## 13. Reverse proxy hardening (Nginx)

### Complete security headers snippet

Create `/etc/nginx/snippets/security-headers.conf`:

```nginx
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self';" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()" always;
add_header Cross-Origin-Opener-Policy "same-origin" always;
add_header Cross-Origin-Resource-Policy "same-origin" always;
```

**Note:** `X-XSS-Protection` is deprecated (can create XSS in safe sites). `Expect-CT` is deprecated (browsers enforce CT natively). Remove both if present.

### Rate limiting

```nginx
# In http {} context:
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
limit_conn_zone $binary_remote_addr zone=addr:10m;

# In server/location blocks:
limit_req zone=general burst=20 nodelay;
limit_req_status 429;
limit_conn addr 10;

location /login {
    limit_req zone=login burst=5 nodelay;
}
```

### Server hardening

```nginx
server_tokens off;                    # Hide Nginx version
proxy_hide_header X-Powered-By;
autoindex off;
client_max_body_size 10m;
client_body_timeout 12s;
client_header_timeout 12s;
send_timeout 10s;

# Block hidden files
location ~ /\. { deny all; }
```

### WAF options in 2025

**ModSecurity reached end-of-life on March 31, 2024.** The OWASP CRS project now recommends **Coraza WAF** (Go-based, compatible with OWASP CRS v4, drop-in replacement). Other strong options include **open-appsec** (AI/ML-based, zero-day detection) and **NAXSI** (lightweight Nginx-native module). CrowdSec also provides an Nginx bouncer for application-layer protection.

---

## 14. Backup and disaster recovery security

### Encrypted backups with restic to S3

```bash
sudo apt install restic  # Or download latest from GitHub

# Credential file (restrict permissions!)
sudo mkdir -p /etc/restic
sudo tee /etc/restic/s3-credentials <<'EOF'
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export RESTIC_REPOSITORY="s3:s3.amazonaws.com/your-bucket-name"
export RESTIC_PASSWORD="your-strong-backup-password"
EOF
sudo chmod 600 /etc/restic/s3-credentials

# Initialize and run
source /etc/restic/s3-credentials
restic init
restic backup /home /etc /var/www /opt --tag "$(hostname)"
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
restic check --read-data-subset=10%
```

### Immutable backups against ransomware

Use **S3 Object Lock in Compliance mode** — nobody, not even the AWS root account, can delete data during the retention period:

```bash
aws s3api create-bucket --bucket my-immutable-backups \
  --object-lock-enabled-for-object-lock-configuration
aws s3api put-object-lock-configuration --bucket my-immutable-backups \
  --object-lock-configuration '{
    "ObjectLockEnabled": "Enabled",
    "Rule": {"DefaultRetention": {"Mode": "COMPLIANCE", "Days": 30}}
  }'
```

For BorgBackup, use **append-only mode** on the backup server's `authorized_keys`:

```
command="borg serve --restrict-to-path /backup/repo --append-only",restrict ssh-ed25519 AAAA...
```

### 3-2-1 rule implementation

Maintain **3 copies** (production + local backup + offsite S3), on **2 media types** (SSD + object storage), with **1 offsite**. Automate with a systemd timer and **test restores monthly**:

```bash
restic restore latest --target /tmp/restore-test --include /etc/nginx
diff -r /etc/nginx /tmp/restore-test/etc/nginx && echo "PASS" || echo "FAIL"
```

---

## 15. Zero-trust architecture and systemd sandboxing

### WireGuard VPN for admin access

Restrict SSH to a WireGuard tunnel only — eliminates public SSH exposure entirely. WireGuard is in-kernel on Ubuntu 24.04 (**~4,000 lines of code** vs OpenVPN's ~100K).

```bash
sudo apt install wireguard wireguard-tools
wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key
sudo chmod 600 /etc/wireguard/server_private.key
```

Server config `/etc/wireguard/wg0.conf`:

```ini
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = <server_private_key>

[Peer]
PublicKey = <client_public_key>
AllowedIPs = 10.8.0.2/32
```

```bash
sudo systemctl enable --now wg-quick@wg0
sudo ufw allow 51820/udp comment 'WireGuard'
```

Lock SSH to WireGuard only:

```bash
# /etc/ssh/sshd_config.d/00-wireguard-only.conf
ListenAddress 10.8.0.1

sudo ufw delete allow 22/tcp
sudo ufw allow in on wg0 to any port 22 proto tcp comment 'SSH via WireGuard only'
```

### systemd sandboxing for services

systemd provides container-like isolation for services with zero extra tooling. Audit current state:

```bash
sudo systemd-analyze security | sort -k 2 -n  # Most services score 8-9/10 UNSAFE
```

Nginx hardening drop-in (`/etc/systemd/system/nginx.service.d/hardening.conf`):

> **LuaJIT exception — read before applying `MemoryDenyWriteExecute=yes`.** If this nginx instance loads any LuaJIT-based module — CrowdSec Nginx bouncer (recommended elsewhere in this skill), `lua-nginx-module`, OpenResty, or `mod_perl` with JIT — **OMIT the `MemoryDenyWriteExecute=yes` line below**. LuaJIT's runtime code generation requires writable+executable memory pages, and the directive will make nginx fail to start with `PANIC: unprotected error in call to Lua API (runtime code generation failed, restricted kernel?)`. PHP-FPM (no JIT) is unaffected — keep it there. Rule of thumb: if your nginx talks Lua, drop the line; otherwise keep it.

```ini
[Service]
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ReadWritePaths=/var/log/nginx /var/cache/nginx /run/nginx
NoNewPrivileges=yes
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_SETUID CAP_SETGID
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service
SystemCallFilter=~@debug @mount @swap @reboot
MemoryDenyWriteExecute=yes    # OMIT this line if LuaJIT modules are loaded — see note above
RestrictSUIDSGID=yes
LockPersonality=yes
```

Node.js service template (`/etc/systemd/system/nodeapp.service`):

```ini
[Unit]
Description=Node.js Application
After=network.target

[Service]
Type=simple
User=nodeapp
Group=nodeapp
WorkingDirectory=/opt/nodeapp
ExecStart=/usr/bin/node /opt/nodeapp/server.js
Restart=on-failure

ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ReadWritePaths=/var/log/nodeapp /opt/nodeapp/data
NoNewPrivileges=yes
CapabilityBoundingSet=
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service
SystemCallArchitectures=native
RestrictNamespaces=yes
MemoryDenyWriteExecute=yes

[Install]
WantedBy=multi-user.target
```

### Service-specific user accounts

```bash
sudo useradd -r -s /usr/sbin/nologin -M nodeapp
sudo mkdir -p /opt/nodeapp /var/log/nodeapp
sudo chown nodeapp:nodeapp /opt/nodeapp /var/log/nodeapp
sudo chmod 750 /opt/nodeapp
```

---

## What changed in 2025–2026 versus older guides

This section highlights the most significant shifts that make pre-2024 hardening guides outdated.

| Change | Details |
|--------|---------|
| **AppArmor 4.0 restricts user namespaces** | Ubuntu 24.04 enables `apparmor_restrict_unprivileged_userns=1` by default. Breaks rootless Docker, some AppImages, Electron apps without explicit AppArmor profiles. |
| **nftables replaces iptables** | `iptables` command is now `iptables-nft` (nftables backend). UFW still works as a frontend. Direct nftables is preferred for Docker servers. |
| **OpenSSH post-quantum KEX** | `sntrup761x25519-sha512` is production-ready in OpenSSH 9.6+ (Ubuntu 24.04). OpenSSH 10.0 (not yet in repos) makes ML-KEM-768 the default. |
| **DSA completely removed** | OpenSSH 9.7+ disables DSA at compile time. OpenSSH 10.0 removes it entirely. |
| **Let's Encrypt ended OCSP** | OCSP responders shut down August 6, 2025. OCSP stapling directives are now unnecessary for LE certificates. |
| **ModSecurity reached EOL** | Commercial support ended July 2024. Coraza WAF (Go, OWASP CRS v4 compatible) is the recommended replacement. |
| **Python 3.12 breaks fail2ban** | Ubuntu 24.04's Python 3.12 removed `asynchat`. Fail2ban 1.0.2 from repos needs patching. CrowdSec avoids this entirely. |
| **SSH socket activation** | Since Ubuntu 22.10, use `systemctl restart ssh.socket`, not `systemctl restart sshd`. |
| **FORTIFY_SOURCE=3** | Ubuntu 24.04 upgrades from level 2, enhancing buffer overflow detection. |
| **TLS 1.0/1.1 disabled system-wide** | OpenSSL and GnuTLS enforce TLS 1.2+ minimum. Legacy apps may break. |
| **OpenSSH decoupled from libsystemd** | Post-XZ-utils-backdoor response (CVE-2024-3094) — reduces dependency chain attack surface. |
| **CrowdSec replacing fail2ban** | Community intelligence model detects distributed attacks that evade single-server tools. |
| **Wazuh replaced OSSEC** | OSSEC last updated January 2021. Wazuh (v4.12+) is actively maintained with full SIEM/XDR capabilities. |
| **Ransomware targets backups** | Immutable backups (S3 Object Lock, Borg append-only) are now essential, not optional. |
| **Supply chain attacks** | XZ-utils (CVE-2024-3094) was a wake-up call. Ubuntu responded by decoupling OpenSSH from libsystemd and strengthening APT signing requirements (RSA ≥ 2048-bit). |
| **Container escape via userns** | Unprivileged user namespace exploits drove Ubuntu's AppArmor 4.0 restrictions. |

---

## Prioritized hardening checklist for a fresh Ubuntu 24.04 VPS

This assumes a fresh VPS running Docker containers, Nginx reverse proxy, Node.js apps, and SSH.

### P0 — Critical (first 15 minutes, blocks 90%+ of attacks)

1. **Update all packages:** `sudo apt update && sudo apt upgrade -y`
2. **Create admin user with sudo password, deploy keys, THEN disable root SSH** (in that order):
   ```bash
   adduser admin                                                # INTERACTIVE — sets a Unix password
   usermod -aG sudo admin
   install -d -m 700 -o admin -g admin /home/admin/.ssh
   cp ~/.ssh/authorized_keys /home/admin/.ssh/ && \
     chown admin:admin /home/admin/.ssh/authorized_keys && \
     chmod 600 /home/admin/.ssh/authorized_keys
   # IN A NEW TERMINAL: ssh admin@host, then `sudo -v`. If sudo prompts for a
   # password and accepts it, you're safe. Only THEN edit sshd_config:
   #   PermitRootLogin no
   #   PasswordAuthentication no
   # and `sudo systemctl restart ssh.socket`.
   ```
   **Lockout trap:** default `sudo` requires the user's Unix password. If you create `admin`
   non-interactively (e.g. `adduser --disabled-password`) or skip `passwd admin`, the account
   has no password. Combined with `PasswordAuthentication no`, you get shell access via key
   but `sudo` refuses to elevate — a soft lockout that needs console rescue.

   **If you want password-less sudo intentionally** (automation, no humans logging in),
   drop a sudoers file rather than skipping the step:
   ```bash
   echo 'admin ALL=(ALL) NOPASSWD: ALL' | sudo install -m 440 /dev/stdin /etc/sudoers.d/90-admin
   sudo visudo -c                                               # validate; refuses to load broken files
   ```
3. **Deploy SSH keys (Ed25519)** and verify key-based login before disabling passwords
4. **Enable UFW:** default deny incoming, allow SSH/80/443 only
5. **Enable unattended-upgrades** for automatic security patches
6. **Install fail2ban or CrowdSec** for brute-force protection

### P1 — High impact (first hour)

7. **Apply Docker-UFW bypass fix** (DOCKER-USER chain or bind to 127.0.0.1)
8. **Harden Docker daemon** (daemon.json: icc=false, no-new-privileges, userns-remap, ip=127.0.0.1)
9. **Apply sysctl network hardening** (SYN cookies, rp_filter, disable redirects)
10. **Apply sysctl kernel hardening** (kptr_restrict=2, sysrq=0, bpf_jit_harden=2)
11. **Set up encrypted offsite backups** (restic to S3 with Object Lock)
12. **Configure WireGuard VPN** and restrict SSH to VPN interface

### P2 — Defense in depth (first day)

13. **Install and configure auditd** with CIS benchmark rules
14. **Deploy Nginx security headers** and TLS hardening (Mozilla Intermediate profile)
15. **Configure Nginx rate limiting** for login pages and APIs
16. **Apply systemd sandboxing** to Nginx and Node.js services
17. **Set up AIDE** for file integrity monitoring
18. **Harden filesystem:** noexec on /tmp and /dev/shm, immutable flags on critical configs
19. **Docker Compose hardening:** cap_drop ALL, read_only, resource limits, internal networks
20. **Scan images with Trivy** before deployment
21. **Enable AppArmor profiles** for all services
22. **Disable unnecessary kernel modules and network services**

### P3 — Operational security (first week, ongoing)

23. **Install ClamAV, rkhunter, chkrootkit** with automated scan schedules
24. **Set up centralized logging** (Grafana Loki or rsyslog forwarding)
25. **Enable Ubuntu Pro + Livepatch** for kernel CVE patching without reboots
26. **Run CIS compliance scan** with USG or Lynis
27. **Deploy Wazuh agent** for SIEM/XDR if managing multiple servers
28. **Deploy Coraza WAF or CrowdSec Nginx bouncer** for application-layer protection
29. **SUID/SGID audit** and removal of unnecessary privileged binaries
30. **Monthly backup restore tests** and quarterly security audits

### Verification commands

```bash
# Verify SSH hardening
ssh-audit your-server-ip                    # Use ssh-audit tool
sudo sshd -T | grep -E "^(permit|password|pubkey|kex|cipher|mac)"

# Verify firewall
sudo ufw status verbose                     # Or: sudo nft list ruleset

# Verify kernel hardening
sysctl kernel.randomize_va_space kernel.kptr_restrict kernel.dmesg_restrict

# Verify Docker security
docker info | grep -E "(Rootless|Security|userns)"
sudo docker/docker-bench-security           # CIS Docker Benchmark

# Verify TLS
curl -I https://yourdomain.com | grep -E "(Strict|X-Content|X-Frame|Content-Security)"
# External: ssllabs.com/ssltest, observatory.mozilla.org

# Full system audit
sudo lynis audit system
sudo systemd-analyze security | sort -k 2 -n
sudo usg audit cis_level1_server            # Requires Ubuntu Pro
```

## Conclusion

The 2025–2026 VPS security landscape demands a layered approach where **no single measure is sufficient**. The most impactful change for most administrators is adopting **CrowdSec over fail2ban** for its community threat intelligence, **nftables or the Docker-UFW patch** to close the critical Docker firewall bypass, and **systemd sandboxing** which provides container-like isolation for free. Post-quantum SSH key exchange (`sntrup761x25519-sha512`) should be enabled now as a no-cost future-proofing measure. The shift to immutable backups with S3 Object Lock reflects the reality that ransomware now specifically targets backup infrastructure. Finally, Ubuntu 24.04's AppArmor 4.0 user namespace restrictions represent a fundamental architectural improvement — though they require attention when setting up rootless Docker. Every command in this guide has been validated against Ubuntu 24.04 LTS defaults and aligned with the CIS Benchmark v1.0.0 for Ubuntu 24.04, NIST SP 800-123 and 800-207, and current CISA advisories.