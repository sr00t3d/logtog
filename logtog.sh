#!/usr/bin/env bash
# ==============================================================================
#  logtog.sh — cPanel Archived Access Logging Auditor & Toggler CLI
# ==============================================================================
#  Author  : Percio Castelo <percio@perciocastelo.com.br>
#  Website : https://perciocastelo.com.br
#  Project : https://perciocastelo.com.br/projetos/en/logtog.html
#  Repo    : https://github.com/sr00t3d/logtog
#  License : Apache-2.0
#  Version : 2.0.0
#  Notes   : Clean-room Bash + Python 3.6+ reimplementation inspired by `logtog`
#            (2011-2012, Jon South / HostGator). Safe `--status` read-only mode
#            by default, explicit `--on`/`--off` + `--prune`/`--no-prune` for
#            `~/.cpanel-logs` (`archive-logs` & `remove-old-archived-logs`),
#            supports usernames > 8 chars, `--user`, `--reseller`, `--all`,
#            `--skip`, `~/logs` disk usage, `--dry-run`, and table/json/csv.
# ==============================================================================

set -uo pipefail
export LC_ALL=C

readonly SCRIPT_NAME="logtog.sh"
readonly SCRIPT_VERSION="2.0.0"

# Defaults
ACTION="status"
PRUNE_SETTING=""
ALL_USERS=0
declare -a TARGET_USERS=()
declare -a RESELLERS=()
declare -a SKIP_USERS=()
DRY_RUN=0
FORMAT="table"
QUIET=0
NO_COLOR=0
TIMESTAMP_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# Colors
RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""

init_colors() {
  if [[ "$NO_COLOR" -eq 0 && -t 1 && -z "${NO_COLOR:-}" && "$FORMAT" == "table" ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    CYAN=$'\033[0;36m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
  else
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
  fi
}

show_help() {
  cat <<'USAGE'
logtog.sh v2.0.0 — cPanel Archived Access Logging Auditor & Toggler CLI

Usage:
  logtog.sh [user ...] [options]
  logtog.sh --all [options]
  logtog.sh --reseller <reseller> --on [options]

Modes:
  --status                 Read-only audit of ~/.cpanel-logs & ~/logs usage (Default)
  --on                     Enable archived logging (archive-logs=1)
  --off                    Disable archived logging (archive-logs=0)
  --prune                  Also set remove-old-archived-logs=1 (monthly cleanup)
  --no-prune               Also set remove-old-archived-logs=0 (keep all archives)

Targets:
  -u, --user <list>        Comma-separated cPanel username(s)
  -r, --reseller <list>    Comma-separated reseller(s) (includes resold accounts)
  --all                    Target all cPanel accounts in /var/cpanel/users
  -s, --skip <list>        Comma-separated username(s) to skip

Options:
  --dry-run                Preview changes without modifying ~/.cpanel-logs
  -o, --output <fmt>       Output format: table (default), json, csv
  -q, --quiet              Suppress banner header
  --no-color               Disable ANSI colors
  -V, --version            Show version and exit
  -h, --help               Show this help and exit

Examples:
  logtog.sh percio
  logtog.sh percio --on --prune
  logtog.sh --all --status -o json
  logtog.sh --reseller res1 --on --skip vipuser --dry-run
  logtog.sh percio --off
USAGE
}

split_csv_into() {
  local raw="$1" target_arr="$2"
  local item IFS=','
  for item in $raw; do
    item="$(printf '%s' "$item" | xargs 2>/dev/null || true)"
    [[ -n "$item" ]] && eval "${target_arr}+=(\"\$item\")"
  done
}

main() {
  command -v python3 >/dev/null 2>&1 || { printf '[ERR] python3 is required.\n' >&2; exit 1; }

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h|--help)        show_help; exit 0 ;;
      -V|--version)     printf '%s %s\n' "$SCRIPT_NAME" "$SCRIPT_VERSION"; exit 0 ;;
      --status)         ACTION="status"; shift ;;
      --on)             ACTION="on"; shift ;;
      --off)            ACTION="off"; shift ;;
      --prune)          PRUNE_SETTING="1"; shift ;;
      --no-prune)       PRUNE_SETTING="0"; shift ;;
      --all)            ALL_USERS=1; shift ;;
      -u|--user)        split_csv_into "${2:-}" TARGET_USERS; shift 2 ;;
      --user=*)         split_csv_into "${1#*=}" TARGET_USERS; shift ;;
      -r|--reseller)    split_csv_into "${2:-}" RESELLERS; shift 2 ;;
      --reseller=*)     split_csv_into "${1#*=}" RESELLERS; shift ;;
      -s|--skip)        split_csv_into "${2:-}" SKIP_USERS; shift 2 ;;
      --skip=*)         split_csv_into "${1#*=}" SKIP_USERS; shift ;;
      --dry-run)        DRY_RUN=1; shift ;;
      -o|--output)      FORMAT="${2:-table}"; shift 2 ;;
      --output=*)       FORMAT="${1#*=}" ; shift ;;
      -q|--quiet)       QUIET=1; shift ;;
      -n|--no-color)    NO_COLOR=1; shift ;;
      -*)               printf '[ERR] Unknown option: %s (use -h for help)\n' "$1" >&2; exit 1 ;;
      *)                split_csv_into "$1" TARGET_USERS; shift ;;
    esac
  done

  case "$FORMAT" in
    table|json|csv) ;;
    *) printf '[ERR] Invalid output format: %s (expected table, json, or csv)\n' "$FORMAT" >&2; exit 1 ;;
  esac

  if [[ ! -f "/usr/local/cpanel/version" ]]; then
    printf '[ERR] cPanel not detected (/usr/local/cpanel/version missing).\n' >&2
    exit 1
  fi

  # Infer user from PWD if no targets specified
  if [[ "$ALL_USERS" -eq 0 && "${#TARGET_USERS[@]}" -eq 0 && "${#RESELLERS[@]}" -eq 0 ]]; then
    local cwd_now
    cwd_now="$(pwd -P)"
    if [[ "$cwd_now" =~ ^/home[0-9]*/([^/]+) ]]; then
      TARGET_USERS+=("${BASH_REMATCH[1]}")
    else
      printf '[ERR] No user specified and current directory (%s) is not under /home*/<user>.\n' "$cwd_now" >&2
      printf '      Usage: %s <user> [--status|--on|--off]  or  %s --all\n' "$SCRIPT_NAME" "$SCRIPT_NAME" >&2
      exit 1
    fi
  fi

  init_colors

  local users_csv resellers_csv skip_csv
  users_csv="$(IFS=,; echo "${TARGET_USERS[*]}")"
  resellers_csv="$(IFS=,; echo "${RESELLERS[*]}")"
  skip_csv="$(IFS=,; echo "${SKIP_USERS[*]}")"

  local py_script
  py_script="$(cat <<'PYEOF'
import csv
import json
import os
import pwd
import shutil
import subprocess
import sys

(
    action, prune_setting, all_users_s, users_csv, resellers_csv, skip_csv,
    dry_run_s, fmt, quiet_s, script_name, script_version, ts_utc,
    c_red, c_green, c_yellow, c_cyan, c_bold, c_reset
) = sys.argv[1:19]

all_users = all_users_s == "1"
dry_run = dry_run_s == "1"
quiet = quiet_s == "1"
skip_set = set(u for u in skip_csv.split(",") if u)
blacklist = {"root", "nobody", "mailman", "mailnull", "rvadmin", "zabbix", "cpanel"}

cpanel_users_dir = "/var/cpanel/users"
all_cp_users = set()
if os.path.isdir(cpanel_users_dir):
    for name in os.listdir(cpanel_users_dir):
        full = os.path.join(cpanel_users_dir, name)
        if os.path.isfile(full) and not name.startswith(".") and name not in blacklist:
            all_cp_users.add(name)

# Map reseller -> owned users
reseller_owned = {}
if os.path.isfile("/etc/trueuserowners"):
    try:
        with open("/etc/trueuserowners", "r", encoding="utf-8", errors="ignore") as f:
            for ln in f:
                if ":" in ln and not ln.lstrip().startswith("#"):
                    u, owner = [p.strip() for p in ln.split(":", 1)]
                    reseller_owned.setdefault(owner, []).append(u)
    except OSError:
        pass

targets = []
if all_users:
    targets = sorted(all_cp_users)
else:
    for r in [x for x in resellers_csv.split(",") if x]:
        if r in blacklist:
            sys.stderr.write(f"[ERR] Protected system user cannot be toggled: {r}\n")
            sys.exit(1)
        owned = reseller_owned.get(r, [])
        if not owned:
            sys.stderr.write(f"[ERR] Reseller not found or owns no accounts: {r}\n")
            sys.exit(1)
        for u in owned:
            if u not in targets:
                targets.append(u)
        if r in all_cp_users and r not in targets:
            targets.append(r)
    for u in [x for x in users_csv.split(",") if x]:
        if u in blacklist:
            sys.stderr.write(f"[ERR] Protected system user cannot be toggled: {u}\n")
            sys.exit(1)
        if u not in all_cp_users:
            sys.stderr.write(f"[ERR] Not a valid cPanel account: {u}\n")
            sys.exit(1)
        if u not in targets:
            targets.append(u)

targets = [u for u in targets if u not in skip_set]
if not targets:
    sys.stderr.write("[ERR] No target cPanel accounts after applying skip list.\n")
    sys.exit(1)

def read_kv(path):
    order = []
    kv = {}
    if os.path.isfile(path):
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            for ln in f:
                s = ln.rstrip("\n")
                if "=" in s and not s.lstrip().startswith("#"):
                    k, v = s.split("=", 1)
                    k, v = k.strip(), v.strip()
                    if k not in kv:
                        order.append(k)
                    kv[k] = v
                elif s.strip():
                    order.append(s)
    return order, kv

def logs_disk_usage(home):
    logs_dir = os.path.join(home, "logs")
    if not os.path.isdir(logs_dir):
        return 0, 0
    count = 0
    total = 0
    try:
        for name in os.listdir(logs_dir):
            fp = os.path.join(logs_dir, name)
            if os.path.isfile(fp):
                count += 1
                total += os.path.getsize(fp)
    except OSError:
        pass
    return count, total

def fmt_bytes(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.1f}{unit}" if unit != "B" else f"{n}B"
        n /= 1024.0

records = []
for u in targets:
    try:
        pw = pwd.getpwnam(u)
    except KeyError:
        continue
    home, uid, gid = pw.pw_dir, pw.pw_uid, pw.pw_gid
    cfg_path = os.path.join(home, ".cpanel-logs")
    order, kv = read_kv(cfg_path)
    cur_arch = kv.get("archive-logs", "0")
    cur_prune = kv.get("remove-old-archived-logs", "0")
    lcount, lbytes = logs_disk_usage(home)

    new_arch = cur_arch
    new_prune = cur_prune
    result_state = "ENABLED" if cur_arch == "1" else "DISABLED"
    changed = False

    if action in ("on", "off"):
        desired_arch = "1" if action == "on" else "0"
        desired_prune = prune_setting if prune_setting in ("0", "1") else cur_prune
        if cur_arch != desired_arch or cur_prune != desired_prune:
            changed = True
            new_arch = desired_arch
            new_prune = desired_prune
            if not dry_run:
                kv["archive-logs"] = new_arch
                if "archive-logs" not in order:
                    order.append("archive-logs")
                if prune_setting in ("0", "1"):
                    kv["remove-old-archived-logs"] = new_prune
                    if "remove-old-archived-logs" not in order:
                        order.append("remove-old-archived-logs")
                out_lines = []
                written = set()
                for item in order:
                    if item in kv and item not in written:
                        out_lines.append(f"{item}={kv[item]}\n")
                        written.add(item)
                    elif item not in kv:
                        out_lines.append(item + "\n")
                with open(cfg_path, "w", encoding="utf-8") as wf:
                    wf.writelines(out_lines)
                try:
                    os.chown(cfg_path, uid, gid)
                    os.chmod(cfg_path, 0o644)
                except OSError:
                    pass
                if shutil.which("logger"):
                    subprocess.run(
                        ["logger", "-t", "logtog", f"archive-logs={new_arch} remove-old-archived-logs={new_prune} for {u} (uid={uid})"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                    )
            result_state = ("WOULD_ENABLE" if dry_run else "ENABLED") if new_arch == "1" else ("WOULD_DISABLE" if dry_run else "DISABLED")
        else:
            result_state = "UNCHANGED"

    records.append({
        "user": u,
        "uid": uid,
        "config_file": cfg_path,
        "archive_logs": new_arch == "1",
        "remove_old_archived_logs": new_prune == "1",
        "changed": changed,
        "state": result_state,
        "log_files": lcount,
        "logs_bytes": lbytes,
    })

summary = {
    "accounts": len(records),
    "enabled": sum(1 for r in records if r["archive_logs"]),
    "disabled": sum(1 for r in records if not r["archive_logs"]),
    "changed": sum(1 for r in records if r["changed"]),
}

if fmt == "json":
    print(json.dumps({
        "tool": script_name,
        "version": script_version,
        "timestamp": ts_utc,
        "action": action,
        "dry_run": dry_run,
        "summary": summary,
        "accounts": records,
    }, indent=2))
elif fmt == "csv":
    w = csv.writer(sys.stdout)
    w.writerow(["user", "uid", "state", "archive_logs", "remove_old_archived_logs", "changed", "log_files", "logs_bytes"])
    for r in records:
        w.writerow([r["user"], r["uid"], r["state"], int(r["archive_logs"]), int(r["remove_old_archived_logs"]), int(r["changed"]), r["log_files"], r["logs_bytes"]])
else:
    if not quiet:
        dlbl = " (DRY-RUN)" if dry_run else ""
        print(f"{c_cyan}{'=' * 96}{c_reset}")
        print(f" {c_bold}{script_name} v{script_version}{c_reset} | cPanel Archived Logging [{action.upper()}{dlbl}] | {ts_utc}")
        print(f"{c_cyan}{'=' * 96}{c_reset}")
    print(f"{'USER':<18} {'STATE':<14} {'ARCHIVE':<9} {'PRUNE':<8} {'~/logs':<16} {'CONFIG FILE'}")
    print(f"{'-'*18} {'-'*14} {'-'*9} {'-'*8} {'-'*16} {'-'*28}")
    for r in records:
        st = r["state"]
        col = c_green if st in ("ENABLED", "WOULD_ENABLE") else (c_yellow if st == "UNCHANGED" else c_red)
        arch_s = "ON" if r["archive_logs"] else "OFF"
        prune_s = "ON" if r["remove_old_archived_logs"] else "OFF"
        linfo = f"{r['log_files']} ({fmt_bytes(r['logs_bytes'])})"
        print(f"{r['user']:<18} {col}{st:<14}{c_reset} {arch_s:<9} {prune_s:<8} {linfo:<16} {r['config_file']}")
    print()
    print(f"Summary: {summary['accounts']} account(s) | {summary['enabled']} archive ON | {summary['disabled']} archive OFF | {summary['changed']} changed")
PYEOF
)"

  python3 -c "$py_script" \
    "$ACTION" "$PRUNE_SETTING" "$ALL_USERS" "$users_csv" "$resellers_csv" "$skip_csv" \
    "$DRY_RUN" "$FORMAT" "$QUIET" "$SCRIPT_NAME" "$SCRIPT_VERSION" "$TIMESTAMP_UTC" \
    "$RED" "$GREEN" "$YELLOW" "$CYAN" "$BOLD" "$RESET"
}

main "$@"
