# ESXiTri Artifact Reference

This document describes each artifact collected by ESXiTri and its forensic relevance.

## Memory

| File | Source | Relevance |
|------|--------|-----------|
| `Active_VMs.txt` | `esxcli vm process list` | Identifies running VMs and their process IDs |
| `Process_List.txt` | `esxcli system process list` | Host-level process inventory |
| `Open_Files.txt` | `lsof` | Files currently open by processes; indicates active usage |
| `ps.txt` | `ps` | Snapshot of running processes |
| `Process_Status.txt` | `cat /proc/meminfo` | Memory utilization at time of collection |
| `Kernel_Modules.txt` | `esxcli system module list` | Loaded kernel modules; useful for detecting unauthorized drivers |
| `Memory_Settings.txt` | `esxcli system settings kernel list` | Kernel memory parameters (ESXi 7.0+) |

## File System

| File | Source | Relevance |
|------|--------|-----------|
| `tmp.tar.gz` | `tar -zcf - /tmp` | Archive of `/tmp` directory; may contain dropped files or scripts |
| `root_MD5_Hashes.txt` | `find / -maxdepth 1 -type f -exec md5sum {} \;` | Hashes of files in root directory |
| `bin_MD5_Hashes.txt` | `find /bin -type f -exec md5sum {} \;` | Hashes of binaries in `/bin` |
| `tmp_MD5_Hashes.txt` | `find /tmp -type f -exec md5sum {} \;` | Hashes of files in `/tmp` |
| `*_Dir_Listing.txt` | `ls -laR` | Directory listings with permissions, sizes, and timestamps |

## Configuration

| File | Source | Relevance |
|------|--------|-----------|
| `ESXi_Version.txt` | `esxcli system version get` | Exact ESXi version, build number, and update level |
| `Hostname.txt` | `esxcli system hostname get` | Hostname and fully qualified domain name |
| `Install_Time.txt` | `esxcli system stats installtime get` | UTC timestamp of ESXi installation |
| `Welcome_Message.txt` | `esxcli system welcomemsg get` | Custom welcome message (sometimes modified by attackers) |
| `System_Advanced_Settings.txt` | `esxcli system settings advanced list` | All advanced settings |
| `System_Advanced_Settings_Non_Default.txt` | `esxcli system settings advanced list --delta` | Only modified settings; highlights attacker changes |
| `vSphere_Installed_Bundles.txt` | `esxcli software vib list` | List of installed VIBs (software packages) |
| `vSphere_Installed_Bundles_Context.txt` | `esxcli software vib get` | Detailed VIB metadata |
| `vSphere_Installed_Bundles_Signature_Verification.txt` | `esxcli software vib signature verify` | VIB signature status; detects unsigned or tampered packages |
| `vSphere_Software_Profiles.txt` | `esxcli software profile get` | Active software profile |
| `BaseImage.txt` | `esxcli software baseimage list` | ESXi 7.0+ base image info |
| `Timezone.txt` | `cat /etc/localtime` | Timezone configuration |
| `Uptime.txt` | `uptime` | Host uptime |
| `Date.txt` | `date` | Collection timestamp |
| `ntp.conf` | `cat /etc/ntp.conf` | NTP server configuration |
| `resolv.conf` | `cat /etc/resolv.conf` | DNS resolver configuration |
| `host.conf` | `cat /etc/host.conf` | Host resolver configuration |
| `nsswitch.conf` | `cat /etc/nsswitch.conf` | Name service switch configuration |
| `USB_Devices.txt` | `lsusb -v` | Connected USB devices |
| `PCI_Devices.txt` | `lspci` | PCI device enumeration |
| `Host_IP_Address.txt` | `hostname -i` | Host IP address |
| `Host_Domain_Name.txt` | `hostname -f` | Host FQDN |
| `hosts` | `cat /etc/hosts` | Static host entries |
| `Crontab/` | `cp -rfp /var/spool/cron/crontabs` | Scheduled tasks; persistence mechanism |
| `init.d/` | `cp -rfp /etc/init.d` | Init scripts; persistence mechanism |
| `rc.local` | `cp -rfp /etc/rc.local` | Local startup script; persistence mechanism |
| `rc.local.d/` | `cp -rfp /etc/rc.local.d` | Additional startup scripts |
| `Hardware_Platform.txt` | `esxcli hardware platform get` | Hardware vendor, model, UUID |
| `Hardware_Clock.txt` | `esxcli hardware clock get` | Hardware clock time |
| `Hardware_CPU_List.txt` | `esxcli hardware cpu list` | CPU topology and features |

## Network

| File | Source | Relevance |
|------|--------|-----------|
| `SNMP_Configuration.txt` | `esxcli system snmp get` | SNMP community strings and targets |
| `Active_Network_Connections.txt` | `esxcli network ip connection list` | Active TCP/UDP connections |
| `ARP_Cache.txt` | `esxcli network ip neighbor list` | ARP table; lateral movement indicators |
| `Network_Adapters.txt` | `esxcli network nic list` | Physical NICs |
| `Network_Interfaces.txt` | `esxcli network ip interface list` | Configured IP interfaces |
| `Network_Interface_IPv4_Configuration.txt` | `esxcli network ip interface ipv4 address list` | IPv4 addresses |
| `Network_Interface_IPv6_Configuration.txt` | `esxcli network ip interface ipv6 address list` | IPv6 addresses |
| `Network_Configuration_VMs.txt` | `esxcli network vm list` | VM network attachments |
| `Domain_Search_Configuration.txt` | `esxcli network ip dns search list` | DNS search domains |
| `DNS_Servers.txt` | `esxcli network ip dns server list` | Configured DNS servers |
| `Virtual_Switches.txt` | `esxcli network vswitch standard list` | Standard vSwitches |
| `vDS_List.txt` | `esxcli network vswitch dvs vmware list` | Distributed vSwitches |
| `Firewall_Status.txt` | `esxcli network firewall get` | Firewall enabled/disabled status |
| `Firewall_Rulesets.txt` | `esxcli network firewall ruleset list` | Firewall ruleset list |
| `Firewall_Ruleset_Rules.txt` | `esxcli network firewall ruleset rule list` | Detailed firewall rules |
| `Firewall_Ruleset_Allowed_IP.txt` | `esxcli network firewall ruleset allowedip list` | IP allowlists per ruleset |
| `VM_Active_Ports.txt` | `esxcli network vm list` | VM port assignments (duplicate for cross-reference) |
| `iSCSI_Adapters.txt` | `esxcli iscsi adapter list` | iSCSI adapter configuration |
| `IPv4_Routes.txt` | `esxcli network ip route ipv4 list` | IPv4 routing table |
| `IPv6_Routes.txt` | `esxcli network ip route ipv6 list` | IPv6 routing table |
| `Netstack_List.txt` | `esxcli network ip netstack list` | TCP/IP stacks (e.g., default, vMotion, provisioning) |
| `Host_Network_Config.txt` | `vim-cmd hostsvc/netconfig` | Complete host network configuration |
| `NIC_Coalesce.txt` | `esxcli network nic coalesce get` | NIC interrupt coalescing |
| `NIC_SG.txt` | `esxcli network nic sg get` | Scatter-gather status |
| `NIC_TSO.txt` | `esxcli network nic tso get` | TCP segmentation offload |
| `ssh/` | `cp -rfp /etc/ssh` | SSH server configuration and host keys |
| `OpenSLP_Status.txt` | `/etc/init.d/slpd status` | Service Location Protocol status |

## Storage

| File | Source | Relevance |
|------|--------|-----------|
| `VMFS_Mounted.txt` | `esxcli storage vmfs extent list` | Mounted VMFS volumes |
| `VMFS_Mappings.txt` | `esxcli storage filesystem list` | All filesystems including VMFS |
| `iSCSI_Paths.txt` | `esxcli storage core path list` | iSCSI multipath details |
| `Device_List.txt` | `esxcli storage core device list` | All storage devices |
| `Device_Detached_List.txt` | `esxcli storage core device detached list` | Detached devices |
| `Device_Partition_List.txt` | `esxcli storage core device partition list` | Partition tables |
| `Device_Partition_List_GUID.txt` | `esxcli storage core device partition showguid` | GPT GUIDs |
| `NFS_Shares.txt` | `esxcli storage nfs list` | NFS v3 mounts |
| `NFSv41_Shares.txt` | `esxcli storage nfs41 list` | NFS v4.1 mounts |
| `Disk_Usage.txt` | `df -h` | Disk space utilization |
| `fdisk.txt` | `fdisk -lu` | Partition layout |
| `HBA_List.txt` | `esxcli storage hba list` | Host bus adapters |
| `Storage_Adapters.txt` | `esxcli storage core adapter list` | All storage adapters |
| `Fibre_Channel.txt` | `esxcli storage san fc list` | FC HBA details |
| `FCoE.txt` | `esxcli storage san fcoe list` | FCoE adapter details |
| `iSCSI_Detailed.txt` | `esxcli storage san iscsi list` | Detailed iSCSI adapter info |
| `NVMe_Devices.txt` | `esxcli storage core device list \| grep -i nvme` | NVMe device subset |
| `Device_World.txt` | `esxcli storage core device world list` | Device-to-world mappings |
| `SMART_Status.txt` | `esxcli storage core device smart get` | SMART health data |

## vSAN

| File | Source | Relevance |
|------|--------|-----------|
| `vSAN_Cluster.txt` | `esxcli vsan cluster get` | vSAN cluster membership and state |
| `vSAN_Storage.txt` | `esxcli vsan storage list` | vSAN disk groups and capacity |
| `vSAN_Network.txt` | `esxcli vsan network list` | vSAN VMkernel ports |
| `vSAN_Objects.txt` | `esxcli vsan debug object list` | vSAN object inventory |

## Accounts

| File | Source | Relevance |
|------|--------|-----------|
| `Accounts.txt` | `esxcli system account list` | ESXi local accounts |
| `Permissions.txt` | `esxcli system permission list` | Role-based permissions |
| `passwd` | `cat /etc/passwd` | Unix user database |
| `shadow` | `cat /etc/shadow` | Password hashes (requires root) |
| `group` | `cat /etc/group` | Unix group database |
| `Account_Policy.txt` | `esxcli system security account-policy get` | AD/LDAP policy settings |

## Security

| File | Source | Relevance |
|------|--------|-----------|
| `SecureBoot.txt` | `esxcli system secureboot get` | UEFI Secure Boot status |
| `TPM_TrustedBoot.txt` | `esxcli hardware trustedboot get` | TPM 2.0 and trusted boot state |
| `VM_Encryption.txt` | `esxcli system settings encryption get` | VM encryption configuration |
| `Shell_Timeout.txt` | `esxcli system settings advanced list -o /UserVars/ESXiShellTimeOut` | ESXi shell timeout |
| `Shell_Interactive_Timeout.txt` | `esxcli system settings advanced list -o /UserVars/ESXiShellInteractiveTimeOut` | Interactive shell timeout |
| `SuppressShellWarning.txt` | `esxcli system settings advanced list -o /UserVars/SuppressShellWarning` | Shell warning suppression |
| `CEIP_OptIn.txt` | `esxcli system settings advanced list -o /UserVars/HostClientCEIPOptIn` | Customer Experience Improvement Program opt-in |
| `SSL_Certificates/` | `cp -rfp /etc/vmware/ssl` | Host SSL certificates and keys |
| `Lockdown_Mode.txt` | `vim-cmd hostsvc/hostsummary \| grep -i lockdown` | Lockdown mode status |

## VMs & Compute

| File | Source | Relevance |
|------|--------|-----------|
| `VM_Inventory.txt` | `vim-cmd vmsvc/getallvms` | All registered VMs |
| `VM_Hardware_Versions.txt` | `vim-cmd hostsvc/vmhardwareversion` | Supported VM hardware versions |
| `Host_Config.txt` | `vim-cmd hostsvc/hostconfig` | Host configuration object |
| `Host_Summary.txt` | `vim-cmd hostsvc/summary` | Host summary (capacity, state) |
| `Advanced_Options.txt` | `vim-cmd hostsvc/advopt/view` | Advanced host options |
| `VM_{id}_Snapshots.txt` | `vim-cmd vmsvc/snapshot.get {id}` | Per-VM snapshot tree |

## Events

| File | Source | Relevance |
|------|--------|-----------|
| `Entity_Permissions.txt` | `vim-cmd vimsvc/auth/entity_permissions` | vCenter entity permissions |
| `Role_List.txt` | `vim-cmd vimsvc/auth/role_list` | Defined vCenter/ESXi roles |

## Logs

| File | Source | Relevance |
|------|--------|-----------|
| `vmsyslog.conf` | `cat /etc/vmsyslog.conf` | Syslog configuration |
| `var_log.tar.gz` | `tar -hzcf - /var/log` | Complete `/var/log` archive |
| `var_run.tar.gz` | `tar -hzcf - /var/run` | `/var/run` archive |
| `scratch_log.tar.gz` | `tar -hzcf - /scratch/log` | Scratch log archive |
| `sysboot.log` | `cat /var/log/sysboot.log` | Boot messages |
| `vmkernel.log` | `cat /var/log/vmkernel.log` | VMkernel messages |
| `vobd.log` | `cat /var/log/vobd.log` | Vobd (observation) log |
| `Syslog_Config.txt` | `esxcli system syslog config get` | Runtime syslog configuration |
| `Audit_Records.txt` | `esxcli system auditrecords get` | Audit record configuration |
| `Archived/` | `find /vmfs/volumes/ -name "*.gz" -exec cp {} ...` | Archived VMkernel logs on VMFS |
| `.ash_history` | `cp -rfp /.ash_history` | Shell command history |

## Integrity

| File | Source | Relevance |
|------|--------|-----------|
| `Hashes.md5` | `find ... -exec md5sum {} \;` | MD5 hashes of all collected files |
| `Hashes.sha256` | `find ... -exec sha256sum {} \;` | SHA-256 hashes of all collected files |
