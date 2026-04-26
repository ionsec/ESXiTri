# ESXiTri Compatibility Matrix

ESXiTri automatically detects the host version and conditionally executes commands that are supported on that platform. Commands that are not available will silently fail and log a warning to `ESXiTri.log` without aborting the script.

## Version Detection

The script parses `esxcli system version get` to extract the major and minor version (e.g., `8.0`). This value is used to gate modern commands.

## Supported Versions

| ESXi Version | Status | Notes |
|-------------|--------|-------|
| 6.5 | Fully Supported | Original target platform |
| 6.7 | Fully Supported | Added `vim-cmd` snapshot collection |
| 7.0 | Fully Supported | Base image, vSAN enhancements, kernel settings |
| 8.0 | Fully Supported | Encryption settings, modern syslog, audit records |
| 8.0 U2+ | Fully Supported | All current namespaces verified |

## Command Availability by Version

### Configuration

| Command | Minimum Version | Notes |
|---------|----------------|-------|
| `esxcli software baseimage list` | 7.0 | Base image replaces traditional VIB-only profiles |
| `esxcli system settings kernel list` | 7.0 | Kernel settings namespace |

### Security

| Command | Minimum Version | Notes |
|---------|----------------|-------|
| `esxcli system secureboot get` | 6.5 | Requires UEFI and Secure Boot enabled hardware |
| `esxcli hardware trustedboot get` | 6.7 | Requires TPM 2.0 |
| `esxcli system settings encryption get` | 7.0 | VM encryption configuration |
| `esxcli system security account-policy get` | 6.7 | AD/LDAP integration policies |

### Storage

| Command | Minimum Version | Notes |
|---------|----------------|-------|
| `esxcli storage nfs41 list` | 6.0 | NFS v4.1 support |
| `esxcli storage san fc list` | 6.5 | Fibre Channel adapters |
| `esxcli storage san fcoe list` | 6.5 | FCoE adapters |
| `esxcli storage core device smart get` | 6.5 | May fail on virtual/unsupported devices |
| `esxcli vsan cluster get` | 6.5 | Requires vSAN license |
| `esxcli vsan debug object list` | 6.5 | Requires vSAN license |

### Network

| Command | Minimum Version | Notes |
|---------|----------------|-------|
| `esxcli network vswitch dvs vmware list` | 6.5 | Requires vDS configured |
| `esxcli network ip netstack list` | 6.5 | TCP/IP stacks |
| `esxcli network nic coalesce get` | 6.5 | May fail on unsupported NICs |

### VMs & Compute

| Command | Minimum Version | Notes |
|---------|----------------|-------|
| `vim-cmd vmsvc/snapshot.get` | 6.5 | Per-VM snapshot trees |
| `vim-cmd hostsvc/vmhardwareversion` | 6.5 | VM hardware version list |
| `vim-cmd hostsvc/advopt/view` | 6.5 | Advanced host options |

### Logs

| Command | Minimum Version | Notes |
|---------|----------------|-------|
| `esxcli system syslog config get` | 6.5 | Modern syslog configuration |
| `esxcli system auditrecords get` | 7.0 | Audit records |

## Fallback Behavior

If a command is not available:
1. The command's stderr is redirected to `ESXiTri.log`
2. A warning line is appended to the log
3. The script continues to the next command
4. No empty files are created for failed commands (the redirection may create a 0-byte file, which is normal)

## Known Limitations

- **vSAN commands** require a vSAN license. Without it, the commands will fail gracefully.
- **TPM/Trusted Boot** requires compatible hardware. The command will fail on hosts without TPM 2.0.
- **VM Encryption** settings require vCenter-managed encryption or host-level key management.
- **NIC offload commands** (`coalesce`, `sg`, `tso`) may fail on virtual NICs or drivers that do not support these features.
- **SMART status** is not available for all storage devices (especially virtual or RAID-backed devices).
- **Fibre Channel / FCoE** commands will fail on hosts without FC/FCoE HBAs.
