# Usage Guide

## Basic Usage

Run all artifact categories with default settings:

```bash
./ESXiTri.sh
```

## CLI Options

### Help and Version

```bash
./ESXiTri.sh --help
./ESXiTri.sh --version
```

### Selective Collection

Run only a specific category:

```bash
./ESXiTri.sh --category network
```

Skip one or more categories:

```bash
./ESXiTri.sh --skip-category logs --skip-category filesystem
```

### Hash Algorithms

Use only SHA-256 (faster, more secure):

```bash
./ESXiTri.sh --hash-only sha256
```

Use only MD5 (legacy compatibility):

```bash
./ESXiTri.sh --hash-only md5
```

### Custom Output Directory

Save the archive to a VMFS datastore instead of `/tmp`:

```bash
./ESXiTri.sh --output-dir /vmfs/volumes/datastore1/collections
```

### Dry-Run Mode

Preview all commands that would be executed without actually running them:

```bash
./ESXiTri.sh --dry-run
```

### Quiet Mode

Suppress all progress output:

```bash
./ESXiTri.sh --quiet
```

## Artifact Categories

| Category | Description |
|----------|-------------|
| `admin` | Directory setup and logging |
| `memory` | Active VMs, processes, open files, kernel modules |
| `filesystem` | `/tmp` archive, binary hashes, directory listings |
| `configuration` | ESXi version, hostname, VIBs, settings, hardware info |
| `network` | Adapters, interfaces, firewall, routes, vSwitches |
| `storage` | VMFS, iSCSI, NFS, devices, partitions |
| `vsan` | vSAN cluster, storage, network, objects |
| `accounts` | Users, groups, permissions, password hashes |
| `security` | Secure Boot, TPM, encryption, certificates, lockdown |
| `vms` | VM inventory, snapshots, hardware versions |
| `events` | Entity permissions, role definitions |
| `logs` | Syslog, VMkernel, Vobd, archived logs, shell history |

## Typical Scenarios

### Rapid Network Triage

```bash
./ESXiTri.sh --category network --category security --hash-only sha256
```

### Full Collection on Datastore

```bash
./ESXiTri.sh --output-dir /vmfs/volumes/datastore1/ir
```

### Excluding Heavy Categories

```bash
./ESXiTri.sh --skip-category logs --skip-category filesystem
```

### Validating Commands Before Execution

```bash
./ESXiTri.sh --dry-run > commands.txt
```

## Error Handling

ESXiTri is designed to never abort mid-collection:

- Unsupported commands fail gracefully with a warning in `ESXiTri.log`
- Version-gated commands only run on compatible ESXi releases
- Missing optional features (e.g., vSAN, TPM) are skipped silently
- The script always attempts to hash and archive whatever was successfully collected
