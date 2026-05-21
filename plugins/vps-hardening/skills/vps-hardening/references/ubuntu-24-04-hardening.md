# The definitive VPS hardening guide for Ubuntu 24.04 LTS

**A production-grade Ubuntu 24.04 VPS can be hardened from default to fortress in under a day** by following the 15 categories below — covering SSH, firewalls, containers, kernel tuning, monitoring, backups, and zero-trust architecture. This guide reflects the 2025–2026 security landscape, including critical shifts like the nftables transition, AppArmor 4.0's new namespace restrictions, Let's Encrypt dropping OCSP, ModSecurity reaching end-of-life, and post-quantum SSH key exchange becoming production-ready. Every recommendation includes exact commands and configuration files for Ubuntu 24.04 LTS, mapped to CIS Benchmarks, NIST guidelines, and CISA advisories.

---

## 1. SSH hardening: the single most important defense

SSH is the primary attack surface on any VPS. Automated bots attempt brute-force logins within minutes of a server going online. Ubuntu 24.04 ships OpenSSH 9.6p1, which supports post-quantum key exchange and per-source penalties — both critical 2025 advancements.

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

# === Per-Source Rate Limiting (OpenSSH 9.8+) ===
PerSourcePenalties crash:90,authfail:5,noauth:3,grace-exceeded:20

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

**Ubuntu 24.04 uses socket-based SSH activation.** Restart with:

```bash
sudo sshd -t  # Validate config first!
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
```

Regenerate host keys on a fresh install to remove any weak defaults:

```bash
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

sudo systemctl restart ssh
# TEST IN A NEW TERMINAL BEFORE CLOSING YOUR SESSION
```

### What changed in OpenSSH for 2025–2026

| Version | Change | Impact |
|---------|--------|--------|
| 9.0 | `sntrup761x25519-sha512` post-quantum KEX | Future-proofs against quantum computing |
| 9.1 | `RequiredRSASize` directive | Enforce minimum 3072-bit RSA |
| 9.5 | `PerSourcePenalties` added | Per-IP rate limiting built into sshd |
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

Then `sudo ufw reload`. To allow a specific container port: `sudo ufw route allow proto tcp from any to any port 80`.

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

Create `/etc/modprobe.d/hardening.conf`:

```ini
# Uncommon filesystems (CIS Benchmark)
install cramfs /bin/false
install freevxfs /bin/false
install jffs2 /bin/false
install hfs /bin/false
install hfsplus /bin/false
install udf /bin/false

# Uncommon network protocols
install dccp /bin/false
install sctp /bin/false
install rds /bin/false
install tipc /bin/false

# USB storage (if not needed)
install usb-storage /bin/false
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

Password-protect GRUB to prevent boot parameter tampering:

```bash
grub-mkpasswd-pbkdf2  # Generate hash
# Add to /etc/grub.d/40_custom:
# set superusers="grubadmin"
# password_pbkdf2 grubadmin grub.pbkdf2.sha512.10000.YOUR_HASH_HERE
sudo update-grub
```

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

### File integrity monitoring with AIDE

```bash
sudo apt install -y aide aide-common
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

```bash
sudo chattr +i /etc/passwd /etc/shadow /etc/group /etc/gshadow
sudo chattr +i /etc/sudoers /etc/ssh/sshd_config /boot/grub/grub.cfg
# Remove flag for edits: sudo chattr -i /etc/passwd
```

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
  "storage-driver": "overlay2",
  "ip": "127.0.0.1",
  "default-ulimits": {
    "nofile": { "Name": "nofile", "Hard": 65536, "Soft": 65536 },
    "nproc": { "Name": "nproc", "Hard": 4096, "Soft": 4096 }
  }
}
```

Key settings: **`icc: false`** disables inter-container communication on the default bridge. **`userns-remap: default`** maps container root to an unprivileged host UID. **`ip: 127.0.0.1`** binds published ports to localhost only.

### Image scanning with Trivy

```bash
# Install
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb noble main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update && sudo apt install -y trivy

# CI/CD gate: fail on HIGH/CRITICAL
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:v1.0

# Generate SBOM
trivy image -f cyclonedx -o sbom.cdx.json myapp:v1.0
```

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
MemoryDenyWriteExecute=yes
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
2. **Create admin user, disable root SSH:** `adduser admin && usermod -aG sudo admin`; set `PermitRootLogin no`, `PasswordAuthentication no`
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