# ESXiTri

**Modern ESXi Incident Response Artifact Collection**

ESXiTri is a comprehensive, dependency-free shell script designed for rapid forensic artifact collection from VMware ESXi hosts during cyber security incidents. It supports ESXi versions **6.5 through 8.0+** and generates a self-contained HTML dashboard for offline analysis.

---

## Why ESXiTri?

During a cyber security incident on VMware infrastructure, time is critical. ESXiTri enables incident responders to:

- **Preserve evidence** before it is lost or tampered with
- **Collect 100+ artifacts** covering memory, storage, network, security, and logs
- **Generate a browser-based dashboard** for immediate offline review
- **Work without dependencies** -- no Python, no agents, no third-party tools

---

## Key Features

- **Version-Aware Collection**: Automatically detects ESXi version and only runs compatible commands
- **12 Artifact Categories**: Memory, FileSystem, Configuration, Network, Storage, vSAN, Accounts, Security, VMs & Compute, Events, Logs
- **HTML Dashboard**: Self-contained `index.html` generated inside every collection
- **Modern Hashing**: MD5 and SHA-256 integrity verification
- **Flexible CLI**: Run all categories, one category, or skip specific categories
- **Dry-Run Mode**: Preview all commands without executing them

---

## Quick Start

```bash
# Copy to ESXi host
scp ESXiTri.sh root@esxi-host:/tmp/

# Execute
ssh root@esxi-host "cd /tmp && chmod +x ESXiTri.sh && ./ESXiTri.sh"

# Download the archive
scp root@esxi-host:/tmp/ESXiTri_*.tar.gz ./

# Extract and open dashboard
tar -xzf ESXiTri_*.tar.gz
open ESXiTri_*/index.html
```

---

## What's New in v2.0

- Full ESXi 8.0+ compatibility with automatic version gating
- New artifact categories: Security, vSAN, VMs & Compute, Events
- SHA-256 hashing alongside MD5
- Self-contained HTML dashboard for offline analysis
- CLI flags for selective collection, dry-run, and quiet mode
- Improved error handling with graceful fallbacks

---

## License

ESXiTri is released under the GNU General Public License v3.0.
