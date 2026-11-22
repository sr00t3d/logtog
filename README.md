[![🇺🇸 English](https://img.shields.io/badge/lang-English-blue.svg)](README.md) [![🇧🇷 Português](https://img.shields.io/badge/lang-Português-green.svg)](README-ptbr.md) [![🇪🇸 Español](https://img.shields.io/badge/lang-Español-yellow.svg)](README-es.md)

# logtog

![logtog cover](logtog-cover.webp)

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/sr00t3d/logtog/releases/tag/v2.0.0)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)](#requirements)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20cPanel-lightgrey.svg)](#requirements)

**cPanel Archived Access Logging Auditor & Toggler CLI (`~/.cpanel-logs`).**

`logtog.sh` audits and toggles cPanel's Raw Access Log archiving (`archive-logs`) and monthly retention cleanup (`remove-old-archived-logs`) for individual users, resellers, or all accounts — defaulting to a **safe read-only `--status` audit** with `~/logs` disk-usage visibility, `--dry-run`, and `table`/`json`/`csv` outputs.

> **Historical Inspiration:** Clean-room Bash + Python 3.6+ `v2.0.0` reimplementation inspired by `logtog` (2011–2012, Jon South / HostGator). Removes the legacy 8-character username limit and hardcoded vendor hostnames, adds read-only `--status` default, `--prune`/`--no-prune`, `~/logs` size reporting, `--dry-run`, and structured JSON/CSV outputs.

---

## Key Features

- **Read-Only `--status` by Default:** Inspect `archive-logs`, `remove-old-archived-logs`, and `~/logs` archive count/size without modifying anything.
- **Full cPanel Retention Control:** Toggle `archive-logs=1|0` (`--on`/`--off`) and `remove-old-archived-logs=1|0` (`--prune`/`--no-prune`) while preserving any other directives and `user:group` ownership (`0644`) in `~/.cpanel-logs`.
- **Flexible Targeting:** Single/multiple users (`-u`), resellers including resold accounts (`-r`), `--all`, `--skip`, or auto-detection from `$PWD` (`/home*/<user>`). Supports modern cPanel usernames longer than 8 characters.
- **Syslog Audit Trail & Automation:** Logs every change via `logger -t logtog`, supports `--dry-run`, `-o table|json|csv`, and Python 3.6+ (RHEL/AlmaLinux 8).

---

## Requirements

- Linux cPanel/WHM server with Bash 4.0+ and Python 3.6+
- Root privileges required to modify other accounts' `~/.cpanel-logs`

---

## Usage

```bash
# Read-only status audit for a cPanel account (or all accounts)
./logtog.sh percio
./logtog.sh --all --status

# Enable archived logging + automatic monthly pruning
./logtog.sh percio --on --prune

# Preview enabling archived logging for a reseller (skipping one VIP user)
./logtog.sh --reseller res1 --on --skip vipacct --dry-run

# Disable archived logging
./logtog.sh percio --off

# Export status report as JSON or CSV
./logtog.sh --all -o json
./logtog.sh --all -o csv
```

### Options

| Flag | Description |
|---|---|
| `--status` | Read-only audit of `~/.cpanel-logs` & `~/logs` usage (default) |
| `--on` | Enable archived logging (`archive-logs=1`) |
| `--off` | Disable archived logging (`archive-logs=0`) |
| `--prune` | Set `remove-old-archived-logs=1` (monthly cleanup) |
| `--no-prune` | Set `remove-old-archived-logs=0` (keep all archives) |
| `-u, --user <list>` | Comma-separated cPanel username(s) |
| `-r, --reseller <list>` | Comma-separated reseller(s) (includes resold accounts) |
| `--all` | Target all cPanel accounts in `/var/cpanel/users` |
| `-s, --skip <list>` | Comma-separated username(s) to skip |
| `--dry-run` | Preview changes without writing `~/.cpanel-logs` |
| `-o, --output <fmt>` | Output format: `table` (default), `json`, `csv` |
| `-q, --quiet` | Suppress header banner |
| `-n, --no-color` | Disable ANSI colors |
| `-V, --version` | Show version and exit |
| `-h, --help` | Show help and exit |

---

## Direct Execution

Run directly without cloning the repository:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/logtog/main/logtog.sh) --all --status
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/logtog/main/logtog.sh) percio --on --prune --dry-run
```

---

## Real Output Example

```text
================================================================================================
 logtog.sh v2.0.0 | cPanel Archived Logging [ON] | 2026-11-22T04:15:00Z
================================================================================================
USER               STATE          ARCHIVE   PRUNE    ~/logs           CONFIG FILE
------------------ -------------- --------- -------- ---------------- ----------------------------
percio             ENABLED        ON        ON       0 (0B)           /home/percio/.cpanel-logs

Summary: 1 account(s) | 1 archive ON | 0 archive OFF | 1 changed
```

---

## Author & License

- **Author:** Percio Castelo — [perciocastelo.com.br](https://perciocastelo.com.br)
- **Project Page:** [perciocastelo.com.br/projetos/en/logtog.html](https://perciocastelo.com.br/projetos/en/logtog.html)
- **License:** [Apache-2.0](LICENSE)
