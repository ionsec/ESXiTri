#!/bin/sh
###################################################################################
#
#    Script:    ESXiTri.sh
#    Version:   2.0
#    Author:    Dan Saunders (Original), Modernized by Community
#    Contact:   dcscoder@gmail.com
#    Purpose:   ESXi Cyber Security Incident Response Script (Shell)
#    Usage:     ./ESXiTri.sh [options]
#
#    This program is free software: you can redistribute it and / or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <https://www.gnu.org/licenses/>.
#
###################################################################################

Version='v2.0'

########## Configuration & Defaults ##########

QUIET=0
CATEGORY=""
SKIP_CATEGORIES=""
HASH_MODE="both"
OUTPUT_DIR=""
DRY_RUN=0
ESXI_VER=""
Triage=""
LOGFILE=""

########## Helper Functions ##########

show_help() {
    cat << 'EOF'
Usage: ./ESXiTri.sh [options]

ESXiTri - ESXi Cyber Security Incident Response Script
Collects forensic artifacts from ESXi hosts (6.5 through 8.0+).

Options:
  -h, --help              Show this help message and exit
  -v, --version           Show version information and exit
  -q, --quiet             Suppress progress output
  --category <name>       Run only the specified category
  --skip-category <name>  Skip the specified category (can be used multiple times)
  --hash-only <mode>      Hash mode: md5, sha256, or both (default: both)
  --output-dir <path>     Custom output directory (default: current directory)
  --dry-run               Print commands without executing them

Categories:
  admin, memory, filesystem, configuration, network,
  storage, accounts, logs, security, vsan, vms, events

Examples:
  ./ESXiTri.sh --category network
  ./ESXiTri.sh --skip-category logs --skip-category filesystem
  ./ESXiTri.sh --hash-only sha256 --output-dir /tmp/collections
EOF
}

show_version() {
    echo "ESXiTri $Version"
    echo "Compatible with ESXi 6.5, 6.7, 7.0, 8.0, and later"
}

msg() {
    if [ "$QUIET" -ne 1 ]; then
        echo "$1"
    fi
}

warn() {
    echo "Warning: $1" >&2
    if [ -n "$LOGFILE" ] && [ -f "$LOGFILE" ]; then
        echo "Warning: $1" >> "$LOGFILE"
    fi
}

# Normalize version string: "8.0.0" -> "800"
# Extracts major and minor only.
version_normalize() {
    _vn_str="$1"
    _vn_major=$(echo "$_vn_str" | cut -d. -f1)
    _vn_minor=$(echo "$_vn_str" | cut -d. -f2)
    # default minor to 0 if missing
    if [ -z "$_vn_minor" ]; then
        _vn_minor=0
    fi
    printf "%d%02d" "$_vn_major" "$_vn_minor"
}

# Check if version $1 >= $2
version_ge() {
    _vg_v1=$(version_normalize "$1")
    _vg_v2=$(version_normalize "$2")
    if [ "$_vg_v1" -ge "$_vg_v2" ]; then
        return 0
    fi
    return 1
}

get_esxi_version() {
    _gev=$(esxcli system version get 2>/dev/null | grep "Version:" | sed 's/.*Version: *//;s/[[:space:]]//g')
    if [ -z "$_gev" ]; then
        _gev="0.0.0"
    fi
    echo "$_gev"
}

should_collect() {
    _sc_cat="$1"
    if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "$_sc_cat" ]; then
        return 1
    fi
    case " $SKIP_CATEGORIES " in
        *" $_sc_cat "*) return 1 ;;
    esac
    return 0
}

run_cmd() {
    _rc_out="$1"
    shift
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] $* > $_rc_out"
        return 0
    fi
    if [ "$QUIET" -ne 1 ]; then
        echo "  -> $*"
    fi
    "$@" > "$_rc_out" 2>> "$LOGFILE"
    _rc_status=$?
    if [ $_rc_status -ne 0 ]; then
        echo "Warning [exit $_rc_status]: $*" >> "$LOGFILE"
    fi
    return $_rc_status
}

generate_dashboard() {
    _dash="$Triage/index.html"
    _host=$(cat "$Triage/Configuration/Hostname.txt" 2>/dev/null | head -n1 | sed 's/.*: //')
    _ver=$(cat "$Triage/Configuration/ESXi_Version.txt" 2>/dev/null | head -n1 | sed 's/.*: //')
    _date=$(cat "$Triage/Configuration/Date.txt" 2>/dev/null)
    _filecount=$(find "$Triage" -type f ! -name "index.html" | wc -l | tr -d ' ')
    _size=$(du -sh "$Triage" 2>/dev/null | cut -f1)
    [ -z "$_host" ] && _host="$(hostname)"
    [ -z "$_ver" ] && _ver="Unknown"
    [ -z "$_date" ] && _date="$(date)"
    [ -z "$_size" ] && _size="Unknown"

    cat > "$_dash" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ESXiTri Dashboard - $_host</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:monospace;background:#1e1e1e;color:#d4d4d4;display:flex;height:100vh;overflow:hidden}
#sidebar{width:300px;background:#252526;border-right:1px solid #333;display:flex;flex-direction:column}
#sidebar h2{padding:15px;background:#2d2d30;border-bottom:1px solid #333;font-size:14px;color:#fff}
#search{padding:10px;border:none;border-bottom:1px solid #333;background:#3c3c3c;color:#fff;outline:none;font-family:monospace}
#filetree{flex:1;overflow-y:auto;padding:10px;font-size:12px}
#filetree ul{list-style:none}
#filetree li{margin:1px 0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#filetree a{color:#ce9178;text-decoration:none;display:block;padding:3px 5px;border-radius:2px}
#filetree a:hover{background:#2a2d2e}
#filetree .dir-label{color:#569cd6;font-weight:bold;padding:4px 0;margin-top:6px;border-bottom:1px solid #333}
#content-area{flex:1;display:flex;flex-direction:column;min-width:0}
#summary{background:#2d2d30;padding:15px;border-bottom:1px solid #333}
#summary h1{font-size:18px;color:#fff;margin-bottom:8px}
#summary table{font-size:12px;color:#858585;border-collapse:collapse}
#summary td{padding:2px 10px 2px 0}
#summary td:first-child{color:#569cd6;font-weight:bold}
#toolbar{background:#252526;padding:8px 15px;border-bottom:1px solid #333;font-size:11px;color:#858585;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#content{flex:1;border:none;background:#1e1e1e;width:100%}
#no-content{display:flex;align-items:center;justify-content:center;height:100%;color:#858585;font-size:14px}
</style>
</head>
<body>
<div id="sidebar">
<h2>ESXiTri Dashboard</h2>
<input type="text" id="search" placeholder="Search artifacts...">
<div id="filetree">
<ul>
EOF

    # Generate file tree grouped by directory
    _prevdir=""
    _tmpfile="/tmp/esxitri_filelist_$$.tmp"
    find "$Triage" -type f ! -name "index.html" | sort > "$_tmpfile"
    while IFS= read -r _f; do
        _rel="${_f#$Triage/}"
        _dir=$(dirname "$_rel")
        _base=$(basename "$_rel")
        if [ "$_dir" != "$_prevdir" ]; then
            if [ -n "$_prevdir" ]; then
                echo "</ul></li>" >> "$_dash"
            fi
            echo "<li class=\"dir-label\">$_dir</li><li><ul>" >> "$_dash"
            _prevdir="$_dir"
        fi
        # Escape single quotes in _rel for the onclick handler
        _rel_escaped=$(echo "$_rel" | sed "s/'/\\\'/g")
        echo "<li><a href=\"#\" onclick=\"loadFile('$_rel_escaped');return false;\">$_base</a></li>" >> "$_dash"
    done < "$_tmpfile"
    rm -f "$_tmpfile"
    if [ -n "$_prevdir" ]; then
        echo "</ul></li>" >> "$_dash"
    fi

    cat >> "$_dash" << 'HTMLEOF'
</ul>
</div>
</div>
<div id="content-area">
<div id="summary">
<h1>ESXiTri Forensic Collection</h1>
<table>
HTMLEOF

    echo "<tr><td>Host</td><td>$_host</td></tr>" >> "$_dash"
    echo "<tr><td>Version</td><td>$_ver</td></tr>" >> "$_dash"
    echo "<tr><td>Collected</td><td>$_date</td></tr>" >> "$_dash"
    echo "<tr><td>Artifacts</td><td>$_filecount files</td></tr>" >> "$_dash"
    echo "<tr><td>Size</td><td>$_size</td></tr>" >> "$_dash"

    cat >> "$_dash" << 'HTMLEOF'
</table>
</div>
<div id="toolbar">Select an artifact from the sidebar to view</div>
<iframe id="content" src="" style="display:none"></iframe>
<div id="no-content">No artifact selected. Click a file in the sidebar.</div>
<script>
function loadFile(path) {
  document.getElementById('content').style.display = 'block';
  document.getElementById('content').src = path;
  document.getElementById('no-content').style.display = 'none';
  document.getElementById('toolbar').textContent = path;
}
document.getElementById('search').addEventListener('input', function(e) {
  var term = e.target.value.toLowerCase();
  var items = document.querySelectorAll('#filetree li');
  items.forEach(function(item) {
    var text = item.textContent.toLowerCase();
    item.style.display = text.indexOf(term) !== -1 ? '' : 'none';
  });
});
</script>
</body>
</html>
HTMLEOF
}

preflight_check() {
    _pwd=$(pwd)
    if [ "$_pwd" = "/" ]; then
        echo "ERROR: Running from '/' will fill the ESXi ramdisk. Please run from /tmp/." >&2
        exit 1
    fi
    # Check available space in current directory (ramdisk or datastore)
    _avail=$(df -h . | tail -n1 | awk '{print $4}')
    msg "Available space in current directory: $_avail"
    # Ensure esxcli is available
    if ! command -v esxcli >/dev/null 2>&1; then
        echo "ERROR: esxcli not found. This script must run on an ESXi host." >&2
        exit 1
    fi
}

########## Argument Parsing ##########

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) show_help; exit 0 ;;
        -v|--version) show_version; exit 0 ;;
        -q|--quiet) QUIET=1; shift ;;
        --category)
            if [ -z "$2" ]; then echo "Error: --category requires an argument" >&2; exit 1; fi
            CATEGORY="$2"; shift 2 ;;
        --skip-category)
            if [ -z "$2" ]; then echo "Error: --skip-category requires an argument" >&2; exit 1; fi
            SKIP_CATEGORIES="$SKIP_CATEGORIES $2"; shift 2 ;;
        --hash-only)
            if [ -z "$2" ]; then echo "Error: --hash-only requires an argument" >&2; exit 1; fi
            HASH_MODE="$2"; shift 2 ;;
        --output-dir)
            if [ -z "$2" ]; then echo "Error: --output-dir requires an argument" >&2; exit 1; fi
            OUTPUT_DIR="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        *) echo "Unknown option: $1" >&2; show_help; exit 1 ;;
    esac
done

if [ -n "$OUTPUT_DIR" ]; then
    if [ ! -d "$OUTPUT_DIR" ]; then
        echo "Error: Output directory does not exist: $OUTPUT_DIR" >&2
        exit 1
    fi
    cd "$OUTPUT_DIR" || exit 1
fi

########## Startup ##########

preflight_check

ESXI_VER=$(get_esxi_version)
msg ""
msg "           _______   _______ ___    ___     __________"
msg "          |   ____| /  _____|\\  \\  /  / __ |___    ___| _______  __"
msg "          |  |____ |   \\___   \\  \\/  / |__|    |  |    |    ___||__|"
msg "          |   ____| \\__    \\  |      | |  |    |  |    |   /    |  |"
msg "          |  |____  ____\\   | /  /\\  \\ |  |    |  |    |  |     |  |"
msg "          |_______||_______/ /__/  \\__\\|__|    |__|    |__|     |__|"
msg ""
msg "Script: ESXiTri.sh - $Version"
msg ""
msg "Detected ESXi version: $ESXI_VER"
msg ""
msg "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
msg ""
msg "Please Note:"
msg "Hi, script running on $(hostname), please do not touch."
msg ""
msg "Bitte beachten Sie:"
msg "Hallo, skript laeuft auf $(hostname), bitte nicht beruehren."
msg ""
msg "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
msg ""
msg "Running script / Ausfuehrendes Skript..."

########## Admin ##########

if should_collect "admin"; then
    msg ""
    msg "(Task 1 / 12) Admin tasks running / Admin-Aufgabe laeuft."

    Destination=$(pwd)
    Timestamp=$(date +%Y%m%d_%H%M%S)
    Endpoint=$(hostname)
    Name="ESXiTri_${Endpoint}_${Timestamp}"
    Triage="$Destination/$Name"
    LOGFILE="$Triage/ESXiTri.log"

    mkdir -p "$Triage"
    chmod 777 "$Triage"

    # Start logging stderr
    exec 2>> "$LOGFILE"
fi

########## Memory ##########

if should_collect "memory"; then
    msg ""
    msg "(Task 2 / 12) Gather memory information / Sammeln von Speicherprozessinformationen."

    mkdir -p "$Triage/Memory"
    chmod 777 "$Triage/Memory"

    run_cmd "$Triage/Memory/Active_VMs.txt" esxcli vm process list
    run_cmd "$Triage/Memory/Process_List.txt" esxcli system process list
    run_cmd "$Triage/Memory/Open_Files.txt" lsof
    run_cmd "$Triage/Memory/ps.txt" ps
    run_cmd "$Triage/Memory/Process_Status.txt" cat /proc/meminfo
    run_cmd "$Triage/Memory/Kernel_Modules.txt" esxcli system module list

    if version_ge "$ESXI_VER" "7.0"; then
        run_cmd "$Triage/Memory/Memory_Settings.txt" esxcli system settings kernel list
    fi
fi

########## File System ##########

if should_collect "filesystem"; then
    msg ""
    msg "(Task 3 / 12) Gather file system information / Sammeln von Dateisysteminformationen."

    mkdir -p "$Triage/FileSystem"
    chmod 777 "$Triage/FileSystem"

    run_cmd "$Triage/FileSystem/tmp.tar.gz" tar -zcf - /tmp
    run_cmd "$Triage/FileSystem/root_MD5_Hashes.txt" find / -maxdepth 1 -type f -exec md5sum {} \;
    run_cmd "$Triage/FileSystem/bin_MD5_Hashes.txt" find /bin -type f -exec md5sum {} \;
    run_cmd "$Triage/FileSystem/tmp_MD5_Hashes.txt" find /tmp -type f -exec md5sum {} \;
    run_cmd "$Triage/FileSystem/root_Dir_Listing.txt" ls -la /
    run_cmd "$Triage/FileSystem/bin_Dir_Listing.txt" ls -laR /bin
    run_cmd "$Triage/FileSystem/tmp_Dir_Listing.txt" ls -laR /tmp
    run_cmd "$Triage/FileSystem/etc_Dir_Listing.txt" ls -laR /etc
fi

########## Configuration ##########

if should_collect "configuration"; then
    msg ""
    msg "(Task 4 / 12) Gather system information / Sammeln von Systeminformationen."

    mkdir -p "$Triage/Configuration"
    chmod 777 "$Triage/Configuration"

    run_cmd "$Triage/Configuration/ESXi_Version.txt" esxcli system version get
    run_cmd "$Triage/Configuration/Hostname.txt" esxcli system hostname get
    run_cmd "$Triage/Configuration/Install_Time.txt" esxcli system stats installtime get
    run_cmd "$Triage/Configuration/Welcome_Message.txt" esxcli system welcomemsg get
    run_cmd "$Triage/Configuration/System_Advanced_Settings.txt" esxcli system settings advanced list
    run_cmd "$Triage/Configuration/System_Advanced_Settings_Non_Default.txt" esxcli system settings advanced list --delta
    run_cmd "$Triage/Configuration/vSphere_Installed_Bundles.txt" esxcli software vib list
    run_cmd "$Triage/Configuration/vSphere_Installed_Bundles_Context.txt" esxcli software vib get
    run_cmd "$Triage/Configuration/vSphere_Installed_Bundles_Signature_Verification.txt" esxcli software vib signature verify
    run_cmd "$Triage/Configuration/vSphere_Software_Profiles.txt" esxcli software profile get
    run_cmd "$Triage/Configuration/Timezone.txt" cat /etc/localtime
    run_cmd "$Triage/Configuration/Uptime.txt" uptime
    run_cmd "$Triage/Configuration/Date.txt" date
    run_cmd "$Triage/Configuration/ntp.conf" cat /etc/ntp.conf
    run_cmd "$Triage/Configuration/resolv.conf" cat /etc/resolv.conf
    run_cmd "$Triage/Configuration/host.conf" cat /etc/host.conf
    run_cmd "$Triage/Configuration/nsswitch.conf" cat /etc/nsswitch.conf
    run_cmd "$Triage/Configuration/USB_Devices.txt" lsusb -v
    run_cmd "$Triage/Configuration/PCI_Devices.txt" lspci
    run_cmd "$Triage/Configuration/Host_IP_Address.txt" hostname -i
    run_cmd "$Triage/Configuration/Host_Domain_Name.txt" hostname -f
    run_cmd "$Triage/Configuration/hosts" cat /etc/hosts
    cp -rfp /var/spool/cron/crontabs "$Triage/Configuration/Crontab" 2>> "$LOGFILE" || true
    cp -rfp /etc/init.d "$Triage/Configuration/init.d" 2>> "$LOGFILE" || true
    cp -rfp /etc/rc.local "$Triage/Configuration/rc.local" 2>> "$LOGFILE" || true
    cp -rfp /etc/rc.local.d "$Triage/Configuration/rc.local.d" 2>> "$LOGFILE" || true
    run_cmd "$Triage/Configuration/Hardware_Platform.txt" esxcli hardware platform get
    run_cmd "$Triage/Configuration/Hardware_Clock.txt" esxcli hardware clock get
    run_cmd "$Triage/Configuration/Hardware_CPU_List.txt" esxcli hardware cpu list

    if version_ge "$ESXI_VER" "7.0"; then
        run_cmd "$Triage/Configuration/BaseImage.txt" esxcli software baseimage list
    fi
fi

########## Network ##########

if should_collect "network"; then
    msg ""
    msg "(Task 5 / 12) Gather network information / Sammeln von Netzwerkinformationen."

    mkdir -p "$Triage/Network"
    chmod 777 "$Triage/Network"

    run_cmd "$Triage/Network/SNMP_Configuration.txt" esxcli system snmp get
    run_cmd "$Triage/Network/Active_Network_Connections.txt" esxcli network ip connection list
    run_cmd "$Triage/Network/ARP_Cache.txt" esxcli network ip neighbor list
    run_cmd "$Triage/Network/Network_Adapters.txt" esxcli network nic list
    run_cmd "$Triage/Network/Network_Interfaces.txt" esxcli network ip interface list
    run_cmd "$Triage/Network/Network_Interface_IPv4_Configuration.txt" esxcli network ip interface ipv4 address list
    run_cmd "$Triage/Network/Network_Interface_IPv6_Configuration.txt" esxcli network ip interface ipv6 address list
    run_cmd "$Triage/Network/Network_Configuration_VMs.txt" esxcli network vm list
    run_cmd "$Triage/Network/Domain_Search_Configuration.txt" esxcli network ip dns search list
    run_cmd "$Triage/Network/DNS_Servers.txt" esxcli network ip dns server list
    run_cmd "$Triage/Network/Virtual_Switches.txt" esxcli network vswitch standard list
    run_cmd "$Triage/Network/Firewall_Status.txt" esxcli network firewall get
    run_cmd "$Triage/Network/Firewall_Rulesets.txt" esxcli network firewall ruleset list
    run_cmd "$Triage/Network/Firewall_Ruleset_Rules.txt" esxcli network firewall ruleset rule list
    run_cmd "$Triage/Network/Firewall_Ruleset_Allowed_IP.txt" esxcli network firewall ruleset allowedip list
    run_cmd "$Triage/Network/VM_Active_Ports.txt" esxcli network vm list
    run_cmd "$Triage/Network/iSCSI_Adapters.txt" esxcli iscsi adapter list
    run_cmd "$Triage/Network/IPv4_Routes.txt" esxcli network ip route ipv4 list
    run_cmd "$Triage/Network/IPv6_Routes.txt" esxcli network ip route ipv6 list
    run_cmd "$Triage/Network/Netstack_List.txt" esxcli network ip netstack list
    run_cmd "$Triage/Network/Host_Network_Config.txt" vim-cmd hostsvc/netconfig

    # vSphere Distributed Switches (vDS)
    esxcli network vswitch dvs vmware list > "$Triage/Network/vDS_List.txt" 2>> "$LOGFILE" || true

    # NIC offloads (may fail on some NICs)
    esxcli network nic coalesce get > "$Triage/Network/NIC_Coalesce.txt" 2>> "$LOGFILE" || true
    esxcli network nic sg get > "$Triage/Network/NIC_SG.txt" 2>> "$LOGFILE" || true
    esxcli network nic tso get > "$Triage/Network/NIC_TSO.txt" 2>> "$LOGFILE" || true

    # SSH
    if [ -d /etc/ssh ]; then
        cp -rfp /etc/ssh "$Triage/Network/" 2>> "$LOGFILE" || true
    fi

    # SLP
    if [ -f /etc/init.d/slpd ]; then
        /etc/init.d/slpd status > "$Triage/Network/OpenSLP_Status.txt" 2>> "$LOGFILE" || true
    fi
fi

########## Storage ##########

if should_collect "storage"; then
    msg ""
    msg "(Task 6 / 12) Gather storage information / Sammeln von Lagerungsinformationen."

    mkdir -p "$Triage/Storage"
    chmod 777 "$Triage/Storage"

    run_cmd "$Triage/Storage/VMFS_Mounted.txt" esxcli storage vmfs extent list
    run_cmd "$Triage/Storage/VMFS_Mappings.txt" esxcli storage filesystem list
    run_cmd "$Triage/Storage/iSCSI_Paths.txt" esxcli storage core path list
    run_cmd "$Triage/Storage/Device_List.txt" esxcli storage core device list
    run_cmd "$Triage/Storage/Device_Detached_List.txt" esxcli storage core device detached list
    run_cmd "$Triage/Storage/Device_Partition_List.txt" esxcli storage core device partition list
    run_cmd "$Triage/Storage/Device_Partition_List_GUID.txt" esxcli storage core device partition showguid
    run_cmd "$Triage/Storage/NFS_Shares.txt" esxcli storage nfs list
    run_cmd "$Triage/Storage/Disk_Usage.txt" df -h
    run_cmd "$Triage/Storage/fdisk.txt" fdisk -lu
    run_cmd "$Triage/Storage/HBA_List.txt" esxcli storage hba list
    run_cmd "$Triage/Storage/Storage_Adapters.txt" esxcli storage core adapter list
    run_cmd "$Triage/Storage/Fibre_Channel.txt" esxcli storage san fc list
    run_cmd "$Triage/Storage/FCoE.txt" esxcli storage san fcoe list
    run_cmd "$Triage/Storage/iSCSI_Detailed.txt" esxcli storage san iscsi list

    # NFS v4.1
    esxcli storage nfs41 list > "$Triage/Storage/NFSv41_Shares.txt" 2>> "$LOGFILE" || true

    # NVMe
    esxcli storage core device list | grep -i nvme > "$Triage/Storage/NVMe_Devices.txt" 2>> "$LOGFILE" || true

    # Device world mapping
    esxcli storage core device world list > "$Triage/Storage/Device_World.txt" 2>> "$LOGFILE" || true

    # SMART (may fail on virtual/unsupported devices)
    esxcli storage core device smart get > "$Triage/Storage/SMART_Status.txt" 2>> "$LOGFILE" || true
fi

########## vSAN ##########

if should_collect "vsan"; then
    msg ""
    msg "(Task 7 / 12) Gather vSAN information / Sammeln von vSAN-Informationen."

    mkdir -p "$Triage/Storage"
    chmod 777 "$Triage/Storage"

    esxcli vsan cluster get > "$Triage/Storage/vSAN_Cluster.txt" 2>> "$LOGFILE" || true
    esxcli vsan storage list > "$Triage/Storage/vSAN_Storage.txt" 2>> "$LOGFILE" || true
    esxcli vsan network list > "$Triage/Storage/vSAN_Network.txt" 2>> "$LOGFILE" || true
    esxcli vsan debug object list > "$Triage/Storage/vSAN_Objects.txt" 2>> "$LOGFILE" || true
fi

########## Accounts ##########

if should_collect "accounts"; then
    msg ""
    msg "(Task 8 / 12) Gather account information / Kontoinformationen sammeln."

    mkdir -p "$Triage/Accounts"
    chmod 777 "$Triage/Accounts"

    run_cmd "$Triage/Accounts/Accounts.txt" esxcli system account list
    run_cmd "$Triage/Accounts/Permissions.txt" esxcli system permission list
    run_cmd "$Triage/Accounts/passwd" cat /etc/passwd
    run_cmd "$Triage/Accounts/shadow" cat /etc/shadow
    run_cmd "$Triage/Accounts/group" cat /etc/group

    # Account policy (AD/LDAP)
    esxcli system security account-policy get > "$Triage/Accounts/Account_Policy.txt" 2>> "$LOGFILE" || true
fi

########## Security ##########

if should_collect "security"; then
    msg ""
    msg "(Task 9 / 12) Gather security information / Sammeln von Sicherheitsinformationen."

    mkdir -p "$Triage/Security"
    chmod 777 "$Triage/Security"

    # Secure Boot
    esxcli system secureboot get > "$Triage/Security/SecureBoot.txt" 2>> "$LOGFILE" || true

    # TPM / Trusted Boot
    esxcli hardware trustedboot get > "$Triage/Security/TPM_TrustedBoot.txt" 2>> "$LOGFILE" || true

    # Encryption settings
    esxcli system settings encryption get > "$Triage/Security/VM_Encryption.txt" 2>> "$LOGFILE" || true

    # Shell timeouts
    esxcli system settings advanced list -o /UserVars/ESXiShellTimeOut > "$Triage/Security/Shell_Timeout.txt" 2>> "$LOGFILE" || true
    esxcli system settings advanced list -o /UserVars/ESXiShellInteractiveTimeOut > "$Triage/Security/Shell_Interactive_Timeout.txt" 2>> "$LOGFILE" || true
    esxcli system settings advanced list -o /UserVars/SuppressShellWarning > "$Triage/Security/SuppressShellWarning.txt" 2>> "$LOGFILE" || true
    esxcli system settings advanced list -o /UserVars/HostClientCEIPOptIn > "$Triage/Security/CEIP_OptIn.txt" 2>> "$LOGFILE" || true

    # Certificates
    if [ -d /etc/vmware/ssl ]; then
        cp -rfp /etc/vmware/ssl "$Triage/Security/SSL_Certificates" 2>> "$LOGFILE" || true
    fi

    # Lockdown mode (via vim-cmd)
    vim-cmd hostsvc/hostsummary | grep -i lockdown > "$Triage/Security/Lockdown_Mode.txt" 2>> "$LOGFILE" || true
fi

########## VMs & Compute ##########

if should_collect "vms"; then
    msg ""
    msg "(Task 10 / 12) Gather VM and compute information / Sammeln von VM-Informationen."

    mkdir -p "$Triage/VMs"
    chmod 777 "$Triage/VMs"

    run_cmd "$Triage/VMs/VM_Inventory.txt" vim-cmd vmsvc/getallvms
    run_cmd "$Triage/VMs/VM_Hardware_Versions.txt" vim-cmd hostsvc/vmhardwareversion
    run_cmd "$Triage/VMs/Host_Config.txt" vim-cmd hostsvc/hostconfig
    run_cmd "$Triage/VMs/Host_Summary.txt" vim-cmd hostsvc/summary
    run_cmd "$Triage/VMs/Advanced_Options.txt" vim-cmd hostsvc/advopt/view

    # Per-VM snapshots
    if [ -f "$Triage/VMs/VM_Inventory.txt" ]; then
        sed '1d' "$Triage/VMs/VM_Inventory.txt" | while read _vmid _rest; do
            [ -z "$_vmid" ] && continue
            case "$_vmid" in
                *[0-9]*) ;;
                *) continue ;;
            esac
            run_cmd "$Triage/VMs/VM_${_vmid}_Snapshots.txt" vim-cmd vmsvc/snapshot.get "$_vmid"
        done
    fi
fi

########## Events ##########

if should_collect "events"; then
    msg ""
    msg "(Task 11 / 12) Gather event and permission information / Sammeln von Ereignisinformationen."

    mkdir -p "$Triage/Events"
    chmod 777 "$Triage/Events"

    vim-cmd vimsvc/auth/entity_permissions > "$Triage/Events/Entity_Permissions.txt" 2>> "$LOGFILE" || true
    vim-cmd vimsvc/auth/role_list > "$Triage/Events/Role_List.txt" 2>> "$LOGFILE" || true
fi

########## Logs ##########

if should_collect "logs"; then
    msg ""
    msg "(Task 12 / 12) Gather log information / Sammeln von Protokollinformationen."

    mkdir -p "$Triage/Logs"
    chmod 777 "$Triage/Logs"
    mkdir -p "$Triage/Logs/Archived"
    chmod 777 "$Triage/Logs/Archived"

    run_cmd "$Triage/Logs/vmsyslog.conf" cat /etc/vmsyslog.conf
    run_cmd "$Triage/Logs/var_log.tar.gz" tar -hzcf - /var/log
    run_cmd "$Triage/Logs/var_run.tar.gz" tar -hzcf - /var/run
    run_cmd "$Triage/Logs/scratch_log.tar.gz" tar -hzcf - /scratch/log
    run_cmd "$Triage/Logs/sysboot.log" cat /var/log/sysboot.log
    run_cmd "$Triage/Logs/vmkernel.log" cat /var/log/vmkernel.log
    run_cmd "$Triage/Logs/vobd.log" cat /var/log/vobd.log

    # Modern syslog config
    esxcli system syslog config get > "$Triage/Logs/Syslog_Config.txt" 2>> "$LOGFILE" || true

    # Audit records
    esxcli system auditrecords get > "$Triage/Logs/Audit_Records.txt" 2>> "$LOGFILE" || true

    # Archived logs on VMFS
    find /vmfs/volumes/ -name "*.gz" -exec cp "{}" "$Triage/Logs/Archived/" \; 2>> "$LOGFILE" || true

    # Ash history
    if [ -f /.ash_history ]; then
        cp -rfp /.ash_history "$Triage/Logs/" 2>> "$LOGFILE" || true
    fi
fi

########## Organise Collection ##########

msg ""
msg "Organising collection / Sammlung organisieren."

# Hashing
if [ "$HASH_MODE" = "md5" ] || [ "$HASH_MODE" = "both" ]; then
    msg "Generating MD5 hashes..."
    find "$Triage" -type f -exec md5sum {} \; > "$Triage/Hashes.md5" 2>> "$LOGFILE"
fi

if [ "$HASH_MODE" = "sha256" ] || [ "$HASH_MODE" = "both" ]; then
    msg "Generating SHA-256 hashes..."
    if command -v sha256sum >/dev/null 2>&1; then
        find "$Triage" -type f -exec sha256sum {} \; > "$Triage/Hashes.sha256" 2>> "$LOGFILE"
    else
        msg "sha256sum not available, skipping SHA-256 hashes."
    fi
fi

# Generate Dashboard
msg "Generating HTML dashboard..."
generate_dashboard

# Compress Archive
msg "Compressing archive..."
if [ "$DRY_RUN" -eq 1 ]; then
    msg "[DRY-RUN] tar -zcf ${Name}.tar.gz $Triage"
else
    tar -zcf "${Name}.tar.gz" "$Triage"

    # Delete Folder
    rm -rf "$Triage"

    msg ""
    msg "Script completed! / Skript abgeschlossen!"
    msg ""
    msg "Archive: ${Name}.tar.gz"
    msg "Dashboard: Open ${Name}/index.html after extraction"
    msg ""
fi
