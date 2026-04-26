# ESXiTri

**ESXi Cyber Security Incident Response Script**

ESXiTri is a comprehensive, dependency-free shell script designed for rapid forensic artifact collection from VMware ESXi hosts during cyber security incidents. It supports ESXi versions **6.5 through 8.0+** and generates a self-contained HTML dashboard for offline analysis.

## What's New in v2.0

- **Modern ESXi Support**: Compatible with ESXi 6.5, 6.7, 7.0, 8.0, and future releases through automatic version detection and command gating.
- **New Artifact Categories**:
  - **Security**: Secure Boot, TPM/Trusted Boot, VM encryption, shell timeouts, lockdown mode, SSL certificates
  - **vSAN**: Cluster, storage, network, and object details (when licensed)
  - **VMs & Compute**: VM inventory, snapshots, hardware versions, host config, resource pools
  - **Events**: vCenter entity permissions and role definitions
  - **Modern Networking**: vSphere Distributed Switches, TCP/IP stacks, IPv4/IPv6 routes, NIC offloads
  - **Modern Storage**: NVMe devices, NFSv4.1, Fibre Channel, FCoE, SMART status
- **SHA-256 Hashing**: Added alongside MD5 for modern integrity verification.
- **Self-Contained HTML Dashboard**: Generates an `index.html` inside the collection that can be opened directly in any browser for easy offline navigation and review.
- **CLI Flags**: Selective category collection, skip categories, dry-run mode, custom output directory, quiet mode, and hash algorithm selection.
- **Improved Error Handling**: Every command is wrapped with graceful fallbacks so the script never aborts mid-collection.

## Description

Once dropped onto the target ESXi host, ESXiTri queries the system using native `esxcli`, `vim-cmd`, and standard Linux tools. Collected data is stored in a temporary folder, hashed (MD5 and/or SHA-256), bundled into a self-contained HTML dashboard, and finally archived into a TAR/GZIP file for offline analysis.

All progress updates are provided in **English and German**.

## Artefacts Supported

### Memory
- Active VMs
- Process List
- Open Files (`lsof`)
- Process Status (`ps`, `/proc/meminfo`)
- Kernel Modules
- Kernel Memory Settings (ESXi 7.0+)

### File System
- `/tmp` archive
- MD5 and SHA-256 binary hashes for `/`, `/bin`, `/tmp`
- Directory listings for `/`, `/bin`, `/tmp`, `/etc`

### Configuration
- ESXi Version, Hostname, Install Time, Welcome Message
- System Advanced Settings (full and non-default delta)
- vSphere Installation Bundles (VIB): list, context, signature verification
- vSphere Software Profiles
- vSphere Base Image (ESXi 7.0+)
- Timezone, Uptime, Date, NTP, DNS Resolver
- USB and PCI Devices
- Host IP Address, Domain Name, Hosts File
- Crontab, `init.d`, `rc.local`, `rc.local.d`
- Hardware Platform, Clock, CPU List

### Network
- SNMP Configuration
- Active Network Connections
- ARP Cache
- Network Adapters and Interfaces
- IPv4 and IPv6 Interface Configuration
- VM Network Configuration
- Domain Search, DNS Servers
- Standard and **Distributed Virtual Switches**
- Firewall Status, Rulesets, Rules, Allowed IPs
- VM Active Ports
- iSCSI Adapters
- **IPv4/IPv6 Routes**
- **TCP/IP Netstacks**
- **NIC Offloads** (coalesce, scatter-gather, TSO)
- SSH Configuration Files
- SLP Status

### Storage
- VMFS Mounted Extents and Mappings
- iSCSI Paths
- Device List, Detached List, Partition List, GUID
- NFS Shares (v3 and **v4.1**)
- Disk Usage (`df`), Partition Table (`fdisk`)
- HBA and Storage Adapter Lists
- **Fibre Channel, FCoE**
- **NVMe Devices**
- Device-to-World Mapping
- SMART Status

### vSAN
- Cluster Configuration
- Storage (Disk Groups)
- Network
- Debug Object List

### Accounts
- ESXi Accounts and Permissions
- `/etc/passwd`, `/etc/shadow`, `/etc/group`
- Account Policy (AD/LDAP integration)

### Security
- **Secure Boot Status**
- **TPM / Trusted Boot Status**
- **VM Encryption Settings**
- ESXi Shell Timeouts
- CEIP Opt-In, Shell Warning Suppression
- **SSL Certificates** (`/etc/vmware/ssl`)
- **Lockdown Mode Status**

### VMs & Compute
- VM Inventory (`vim-cmd`)
- VM Hardware Versions
- Host Configuration and Summary
- Advanced Options
- **Per-VM Snapshot Trees**

### Events
- Entity Permissions
- Role List

### Logs
- `vmsyslog.conf`
- `/var/log/*`, `/var/run/*`, `/scratch/log/*`
- **Syslog Configuration**
- **Audit Records**
- Boot, VMkernel, and Vobd logs
- Archived Logs from VMFS
- Ash History

## Usage

### Basic Usage

Copy `ESXiTri.sh` to the target host `/tmp/` directory via SCP or datastore:

```bash
chmod +x ./ESXiTri.sh
./ESXiTri.sh
```

Download the resultant `*.tar.gz` archive via SCP, then clean up:

```bash
rm ./ESXiTri.sh
rm ./ESXiTri_<hostname>_<date>_<time>.tar.gz
```

### Advanced Options

```bash
# Run only the network category
./ESXiTri.sh --category network

# Skip logs and filesystem to save space
./ESXiTri.sh --skip-category logs --skip-category filesystem

# Use only SHA-256 hashes
./ESXiTri.sh --hash-only sha256

# Custom output directory
./ESXiTri.sh --output-dir /vmfs/volumes/datastore1/collections

# Dry-run to preview commands without executing
./ESXiTri.sh --dry-run

# Quiet mode (minimal output)
./ESXiTri.sh --quiet
```

### Dashboard

After extraction, open the generated `index.html` inside the collection folder in any modern web browser:

```bash
tar -xzf ESXiTri_<hostname>_<date>_<time>.tar.gz
open ESXiTri_<hostname>_<date>_<time>/index.html
```

The dashboard provides:
- A navigable file tree of all collected artifacts
- A summary panel with host details, file count, and collection size
- Real-time search/filter
- Inline viewing of text artifacts via an iframe

*Note: If your browser blocks local file access, serve the folder with a simple HTTP server:*
```bash
cd ESXiTri_<hostname>_<date>_<time>
python3 -m http.server 8080
```

## Requirements

- VMware ESXi host (6.5 or later)
- `esxcli` and `vim-cmd` (included in all ESXi installations)
- Native Linux/ESXi tools (`find`, `tar`, `md5sum`, `sha256sum`)
- **No third-party tools are required.**

## Testing

- Tested on VMware ESXi 6.5, 6.7, 7.0, and 8.0
- Ensure you run the script from `/tmp/` or a VMFS datastore -- **not from `/`** -- to avoid filling the ESXi ramdisk.
- The script includes a pre-flight check to warn if running from `/`.

## Documentation

- [Compatibility Matrix](docs/COMPATIBILITY.md) -- ESXi version-specific command availability
- [Artifact Reference](docs/ARTIFACTS.md) -- Detailed description of each collected artifact
- [Dashboard Guide](docs/DASHBOARD.md) -- How to use the generated HTML dashboard

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## Author

- **Original Author**: Dan Saunders (dcscoder@gmail.com)
- **Modernized by**: Community contributors
