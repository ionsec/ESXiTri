# Changelog

## v2.0 (2026-04-26)

### Added
- Full ESXi 6.5 through 8.0+ compatibility with automatic version detection
- 5 new artifact categories: Security, vSAN, VMs & Compute, Events, modern Networking/Storage
- Self-contained HTML dashboard (`index.html`) generated inside every collection
- SHA-256 hashing alongside existing MD5
- CLI flags: `--help`, `--version`, `--category`, `--skip-category`, `--hash-only`, `--output-dir`, `--dry-run`, `--quiet`
- Pre-flight checks for working directory and available disk space
- Graceful error handling with per-command fallbacks
- Documentation: COMPATIBILITY.md, ARTIFACTS.md, DASHBOARD.md
- MkDocs + Read the Docs integration

### Changed
- Major rewrite of `ESXiTri.sh` with POSIX sh compatibility
- Progress messages updated to reflect 12 categories
- Archive now includes integrity hashes and dashboard

### Fixed
- Script no longer aborts when individual commands fail
- Version-gated commands prevent errors on older ESXi releases

## v1.5

- Original release by Dan Saunders
- Tested on VMware ESXi 6.5.0d
- Collected 9 artifact categories
- MD5-only hashing
