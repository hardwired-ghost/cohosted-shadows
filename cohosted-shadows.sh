#!/usr/bin/env bash
#
# Passive-DNS reverse-IP history + live verification
#
# Usage: ./cohosted-shadows.sh <IP>
#
set -euo pipefail

# Colors (auto-disabled when not writing to a terminal, or if NO_COLOR is set)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_GREEN=$'\033[32m'; C_ORANGE=$'\033[33m'; C_RED=$'\033[31m'
  C_DIM=$'\033[2m'; C_RESET=$'\033[0m'
else
  C_GREEN=''; C_ORANGE=''; C_RED=''; C_DIM=''; C_RESET=''
fi

IP="${1:-}"
if [[ -z "$IP" ]]; then
  echo "Usage: $0 <IP>" >&2
  exit 1
fi

# basic IPv4 sanity check
if ! [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "Error: '$IP' is not a valid IPv4 address" >&2
  exit 1
fi

echo ".::HΔRDWIRΞD ∇ GH0ST::."
echo "    every ip has a past. this tool reads it."
echo "[*] Target IP : $IP"
echo "[*] Step 1: fetching passive-DNS history from rapiddns.io ..."

# 1 - reverse history
HOSTS="$(curl -s "https://rapiddns.io/sameip/${IP}?full=1" 2>/dev/null \
  | grep -oP '(?<=<td>)[a-zA-Z0-9._-]+\.[a-zA-Z]{2,}(?=</td>)' \
  | sort -u || true)"

if [[ -z "$HOSTS" ]]; then
  echo "[!] No historical hostnames found (or rapiddns rate-limited / unreachable)." >&2
  exit 0
fi

TOTAL=$(echo "$HOSTS" | wc -l | tr -d ' ')
echo "[*] Found $TOTAL historical hostname(s)."
echo "[*] Step 2: live dig A on each host ..."
echo

alive=0; moved=0; dead=0

# 2 - dig A to see what's really alive
while IFS= read -r host; do
  [[ -z "$host" ]] && continue
  ips=$(dig +short +time=2 +tries=1 A "$host" 2>/dev/null | grep -E '^[0-9]+\.' | paste -sd, - || true)

  if [[ -z "$ips" ]]; then
    status="DEAD   "; mark="x"; color="$C_RED";    dead=$((dead+1))
  elif echo "$ips" | tr ',' '\n' | grep -qx "$IP"; then
    status="CURRENT"; mark="+"; color="$C_GREEN";  alive=$((alive+1))
  else
    status="MOVED  "; mark="-"; color="$C_ORANGE"; moved=$((moved+1))
  fi

  printf "${color}[%s] %-6s %-38s${C_RESET} ${C_DIM}%s${C_RESET}\n" \
    "$mark" "$status" "$host" "$ips"
done <<< "$HOSTS"

echo
echo "[*] Summary: ${C_GREEN}$alive current on $IP${C_RESET} | ${C_ORANGE}$moved moved away${C_RESET} | ${C_RED}$dead dead (no A record)${C_RESET}"

# print just the survivors for easy copy/paste
if (( alive > 0 )); then
  echo
  echo "[*] Hosts CURRENT on $IP:"
  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    dig +short +time=2 +tries=1 A "$host" 2>/dev/null \
      | grep -qx "$IP" && echo "$host" || true
  done <<< "$HOSTS"
fi

exit 0
