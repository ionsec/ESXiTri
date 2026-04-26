# ESXiTri Dashboard Guide

ESXiTri automatically generates a **self-contained HTML dashboard** (`index.html`) inside the collected artifact folder. This dashboard provides an intuitive, browser-based interface for reviewing forensic artifacts without requiring any server-side infrastructure.

## Opening the Dashboard

### After Extraction

```bash
tar -xzf ESXiTri_hostname_20240115_143022.tar.gz
cd ESXiTri_hostname_20240115_143022
open index.html        # macOS
xdg-open index.html    # Linux
start index.html       # Windows
```

### Directly from the Archive

You can also extract just the dashboard file:

```bash
tar -xzf ESXiTri_hostname_20240115_143022.tar.gz ESXiTri_hostname_20240115_143022/index.html
```

## Dashboard Features

### Summary Panel

At the top of the dashboard, you will see:
- **Host**: The collected ESXi hostname
- **Version**: The ESXi version string
- **Collected**: The date and time of collection
- **Artifacts**: Total number of files collected
- **Size**: Total size of the collection

### Sidebar Navigation

The left sidebar contains a searchable, categorized file tree:
- Artifacts are grouped by directory (e.g., `Memory`, `Network`, `Security`)
- Click any file name to view its contents
- Use the **Search** box to filter artifacts by name or path

### Content Viewer

The main area displays the selected artifact:
- Text files are rendered in a monospace font within an iframe
- Binary archives (`.tar.gz`) will prompt for download or display as raw data depending on the browser
- The current file path is shown in the toolbar above the viewer

## Browser Compatibility

The dashboard uses only HTML, CSS, and vanilla JavaScript with no external dependencies.

| Browser | Compatibility | Notes |
|---------|--------------|-------|
| Chrome / Edge | Full | Recommended |
| Firefox | Full | Recommended |
| Safari | Full | Recommended |
| Internet Explorer 11 | Partial | Layout may degrade; search works |

## Local File Access (CORS)

Because the dashboard loads artifacts via `<iframe>` from the local filesystem, some browsers may restrict this behavior in certain security zones.

### If the Dashboard Shows Blank Content

If clicking a file shows nothing, your browser may be blocking local iframe loading. Use one of these workarounds:

**Option 1: Python HTTP Server (Recommended)**

```bash
cd ESXiTri_hostname_20240115_143022
python3 -m http.server 8080
# Then open http://localhost:8080 in your browser
```

**Option 2: Node.js HTTP Server**

```bash
cd ESXiTri_hostname_20240115_143022
npx serve .
```

**Option 3: macOS Quick Server**

```bash
cd ESXiTri_hostname_20240115_143022
python3 -m SimpleHTTPServer 8080
```

## Customization

The dashboard is generated dynamically by the script. If you wish to customize the appearance:

1. Extract the archive
2. Edit `index.html` with any text editor
3. The CSS is embedded in the `<style>` block near the top
4. The color scheme uses a dark theme by default

## Security Notes

- The dashboard contains **sensitive forensic data**. Protect it accordingly.
- Do not upload the dashboard or archive to public services.
- The dashboard does not make any external network requests.
