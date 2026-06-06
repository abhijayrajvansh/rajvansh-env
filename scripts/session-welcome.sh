#!/bin/bash

timestamp="$(date '+%Y-%m-%d %H:%M:%S %Z')"
user_name="$(id -un 2>/dev/null || printf 'unknown')"
host_name="$(hostname -s 2>/dev/null || hostname 2>/dev/null || printf 'unknown')"
tty_name="$(tty 2>/dev/null)"
if [[ $? -ne 0 || -z "$tty_name" ]]; then
  tty_name="not a tty"
fi

ip_address="$(
  ipconfig getifaddr en0 2>/dev/null ||
  ipconfig getifaddr en1 2>/dev/null ||
  ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" { print $2; exit }'
)"
ip_address="${ip_address:-unavailable}"

if who 2>/dev/null | awk -v user="$user_name" '$1 == user { found = 1 } END { exit !found }'; then
  login_status="logged in"
else
  login_status="active shell user"
fi

green=$'\033[0;32m'
blue=$'\033[0;34m'
reset=$'\033[0m'

title="machine details:"
detail_lines=(
  "timestamp: $timestamp"
  "login status: $login_status as $user_name"
  "hostname: $host_name"
  "ip address: $ip_address"
  "terminal: $tty_name"
)
display_lines=(
  "timestamp: $timestamp"
  "login status: $login_status as ${green}${user_name}${reset}"
  "hostname: ${blue}${host_name}${reset}"
  "ip address: $ip_address"
  "terminal: $tty_name"
)

max_width=${#title}
for line in "${detail_lines[@]}"; do
  if (( ${#line} > max_width )); then
    max_width=${#line}
  fi
done

border="$(printf '%*s' "$((max_width + 2))" '' | tr ' ' '-')"

printf '\n'
printf '→ WELCOME BACK, MR. RAJVANSH.\n'
printf '\n'
printf '→ injecting scripts\n'
printf '→ jasmine link established\n'
printf '+%s+\n' "$border"
printf '| %-*s |\n' "$max_width" "$title"
printf '+%s+\n' "$border"
for i in "${!detail_lines[@]}"; do
  padding=$((max_width - ${#detail_lines[$i]}))
  printf '| %s%*s |\n' "${display_lines[$i]}" "$padding" ''
done
printf '+%s+\n\n' "$border"
