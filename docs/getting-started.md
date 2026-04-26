# Getting Started

## Requirements

- VMware ESXi host (version 6.5 or later)
- `esxcli` and `vim-cmd` (included in all ESXi installations)
- Standard Linux/ESXi utilities: `find`, `tar`, `md5sum`, `sha256sum`
- **No third-party tools required**

## Installation

ESXiTri is a single shell script. No installation is required.

### Step 1: Download

```bash
curl -O https://raw.githubusercontent.com/ionsec/ESXiTri/main/ESXiTri.sh
```

### Step 2: Copy to Target Host

Use SCP or place the script on a shared VMFS datastore accessible by the ESXi host:

```bash
scp ESXiTri.sh root@esxi-host:/tmp/
```

### Step 3: Set Permissions

```bash
ssh root@esxi-host "chmod +x /tmp/ESXiTri.sh"
```

### Step 4: Run

```bash
ssh root@esxi-host "cd /tmp && ./ESXiTri.sh"
```

!!! warning "Run from /tmp or a datastore"
    Never run ESXiTri from the root filesystem `/`. ESXi's ramdisk is very small and filling it can crash the host. Always run from `/tmp/` or a VMFS datastore.

### Step 5: Retrieve Collection

```bash
scp root@esxi-host:/tmp/ESXiTri_*.tar.gz ./
```

### Step 6: Open Dashboard

```bash
tar -xzf ESXiTri_*.tar.gz
cd ESXiTri_*
python3 -m http.server 8080
# Open http://localhost:8080 in your browser
```

## Pre-Flight Checks

ESXiTri automatically performs the following checks before collection:

1. **Working Directory**: Exits if running from `/`
2. **Disk Space**: Reports available space in the current directory
3. **Tool Availability**: Verifies `esxcli` is present

## Post-Collection Cleanup

```bash
ssh root@esxi-host "rm /tmp/ESXiTri.sh /tmp/ESXiTri_*.tar.gz"
```
