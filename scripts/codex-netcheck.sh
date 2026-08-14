#!/usr/bin/env bash

# Watch the endpoints that power the Codex CLI on this machine.
# Checks the official Codex backend and the opencode.ai upstream,
# prints a live status line, and sends local and ntfy heartbeat alerts.

set -u

OFFICIAL_URL="${CODEX_NETCHECK_OFFICIAL_URL:-https://chatgpt.com/backend-api/codex}"
UPSTREAM_URL="${CODEX_NETCHECK_UPSTREAM:-https://opencode.ai/zen/go/v1/models}"
INTERVAL="${CODEX_NETCHECK_INTERVAL:-5}"
TIMEOUT="${CODEX_NETCHECK_TIMEOUT:-6}"
LOG_FILE="${CODEX_NETCHECK_LOG:-$HOME/.codex/codex-netcheck.log}"
NTFY_SERVER="${CODEX_NETCHECK_NTFY_SERVER:-https://ntfy.sh}"
NTFY_TOPIC="${CODEX_NETCHECK_NTFY_TOPIC:-}"
NTFY_TOKEN="${CODEX_NETCHECK_NTFY_TOKEN:-}"
HEARTBEAT_MINUTES="${CODEX_NETCHECK_HEARTBEAT_MINUTES:-10}"
TOPIC_FILE="${CODEX_NETCHECK_NTFY_TOPIC_FILE:-$HOME/.config/codex-netcheck/ntfy-topic}"

ONCE=0
NOTIFY=1
NTFY_ENABLED=1
SETUP_NTFY=0
SHOW_TOPIC=0

usage() {
  cat <<'EOF'
Usage: codex-netcheck [options]

Checks the official Codex backend and the opencode.ai upstream used by
Codex, then keeps watching them until interrupted. When ntfy is configured,
an "online" heartbeat is sent to your phone at the selected interval. If the
heartbeat stops arriving, the Mac or its Codex connection is unavailable.

Options:
  --once                 Run a single check and exit
  --interval SECS        Seconds between endpoint checks (default: 5)
  --timeout SECS         Per-request timeout (default: 6)
  --heartbeat MINUTES    ntfy heartbeat interval (default: 10; try 5 or 15)
  --ntfy-topic TOPIC     ntfy topic for this run
  --ntfy-server URL      ntfy server (default: https://ntfy.sh)
  --setup-ntfy           Generate and save a private topic, then send a test
  --show-topic           Print the saved topic and exit
  --no-ntfy              Disable phone notifications
  --no-notify            Disable macOS notifications on state changes
  -h, --help             Show this help

Environment:
  CODEX_NETCHECK_OFFICIAL_URL       Official Codex backend URL override
  CODEX_NETCHECK_UPSTREAM           Upstream reachability URL override
  CODEX_NETCHECK_INTERVAL           Same as --interval
  CODEX_NETCHECK_TIMEOUT            Same as --timeout
  CODEX_NETCHECK_LOG                Event log path
  CODEX_NETCHECK_HEARTBEAT_MINUTES  Same as --heartbeat
  CODEX_NETCHECK_NTFY_SERVER        Same as --ntfy-server
  CODEX_NETCHECK_NTFY_TOPIC         Same as --ntfy-topic
  CODEX_NETCHECK_NTFY_TOKEN         Optional Bearer token for protected topics
  CODEX_NETCHECK_NTFY_TOPIC_FILE    Saved topic path
EOF
}

require_value() {
  if (( $# < 2 )) || [[ -z "$2" ]]; then
    printf 'Option %s requires a value.\n' "$1" >&2
    exit 2
  fi
}

while (( $# > 0 )); do
  case "$1" in
    --once) ONCE=1 ;;
    --interval) require_value "$@"; INTERVAL="$2"; shift ;;
    --timeout) require_value "$@"; TIMEOUT="$2"; shift ;;
    --heartbeat) require_value "$@"; HEARTBEAT_MINUTES="$2"; shift ;;
    --ntfy-topic) require_value "$@"; NTFY_TOPIC="$2"; shift ;;
    --ntfy-server) require_value "$@"; NTFY_SERVER="$2"; shift ;;
    --setup-ntfy) SETUP_NTFY=1 ;;
    --show-topic) SHOW_TOPIC=1 ;;
    --no-ntfy) NTFY_ENABLED=0 ;;
    --no-notify) NOTIFY=0 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ! "$INTERVAL" =~ ^[1-9][0-9]*$ ]]; then
  printf 'Check interval must be a positive whole number of seconds.\n' >&2
  exit 2
fi
if [[ ! "$TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
  printf 'Timeout must be a positive whole number of seconds.\n' >&2
  exit 2
fi
if [[ ! "$HEARTBEAT_MINUTES" =~ ^[1-9][0-9]*$ ]]; then
  printf 'Heartbeat interval must be a positive whole number of minutes.\n' >&2
  exit 2
fi

NTFY_SERVER="${NTFY_SERVER%/}"
HEARTBEAT_SECONDS=$((HEARTBEAT_MINUTES * 60))

load_saved_topic() {
  if [[ -z "$NTFY_TOPIC" && -r "$TOPIC_FILE" ]]; then
    IFS= read -r NTFY_TOPIC < "$TOPIC_FILE"
  fi
}

validate_topic() {
  [[ "$NTFY_TOPIC" =~ ^[A-Za-z0-9_-]+$ ]]
}

send_ntfy() {
  local title="$1"
  local message="$2"
  local tags="$3"
  local priority="$4"
  local -a curl_args

  (( NTFY_ENABLED )) || return 0
  [[ -n "$NTFY_TOPIC" ]] || return 1

  curl_args=(
    -fsS -o /dev/null
    --connect-timeout "$TIMEOUT"
    --max-time "$TIMEOUT"
    -X POST
    -H "Title: $title"
    -H "Tags: $tags"
    -H "Priority: $priority"
    --data-binary "$message"
  )
  if [[ -n "$NTFY_TOKEN" ]]; then
    curl_args+=(-H "Authorization: Bearer $NTFY_TOKEN")
  fi
  curl "${curl_args[@]}" "$NTFY_SERVER/$NTFY_TOPIC"
}

setup_ntfy() {
  local generated_topic
  if [[ -n "$NTFY_TOPIC" ]]; then
    generated_topic="$NTFY_TOPIC"
  elif command -v openssl >/dev/null 2>&1; then
    generated_topic="codex-netcheck-$(openssl rand -hex 16)"
  else
    generated_topic="codex-netcheck-$(date +%s)-$RANDOM$RANDOM"
  fi

  NTFY_TOPIC="$generated_topic"
  if ! validate_topic; then
    printf 'ntfy topic may contain only letters, numbers, underscores, and hyphens.\n' >&2
    exit 2
  fi

  mkdir -p "$(dirname "$TOPIC_FILE")"
  umask 077
  printf '%s\n' "$NTFY_TOPIC" > "$TOPIC_FILE"
  chmod 600 "$TOPIC_FILE"

  if send_ntfy "Codex netcheck is ready" "Subscribe to this topic. Online heartbeats will arrive every ${HEARTBEAT_MINUTES} minutes while Codex connectivity is healthy." "white_check_mark,signal_strength" "high"; then
    printf 'ntfy setup complete. Subscribe to this topic in the ntfy phone app:\n%s\n' "$NTFY_TOPIC"
  else
    printf 'Topic saved, but the test notification could not be sent.\n' >&2
    printf 'Saved topic: %s\n' "$NTFY_TOPIC" >&2
    exit 1
  fi
}

load_saved_topic

if (( SHOW_TOPIC )); then
  if [[ -n "$NTFY_TOPIC" ]]; then
    printf '%s\n' "$NTFY_TOPIC"
    exit 0
  fi
  printf 'No ntfy topic is configured. Run codex-netcheck --setup-ntfy.\n' >&2
  exit 1
fi

if (( SETUP_NTFY )); then
  setup_ntfy
  exit 0
fi

if [[ -n "$NTFY_TOPIC" ]] && ! validate_topic; then
  printf 'ntfy topic may contain only letters, numbers, underscores, and hyphens.\n' >&2
  exit 2
fi

mkdir -p "$(dirname "$LOG_FILE")"

log_event() {
  local stamp
  stamp="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '%s %s\n' "$stamp" "$*" | tee -a "$LOG_FILE"
}

notify() {
  (( NOTIFY )) || return 0
  command -v osascript >/dev/null 2>&1 || return 0
  osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1
}

check_one() {
  local url="$1"
  local out code rc
  out="$(curl -sS -o /dev/null --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" \
    -w '%{http_code}|%{time_total}' "$url" 2>/dev/null)"
  rc=$?
  code="${out%%|*}"
  if (( rc == 0 )) && [[ "$code" =~ ^[0-9]{3}$ ]] && [[ "$code" != "000" ]]; then
    printf '%s|%s' "$code" "${out#*|}"
    return 0
  fi
  printf '%s|0' "000"
  return 1
}

render() {
  local line="$1"
  printf '%s\n' "$line"
}

run_checks() {
  local official_code official_ms upstream_code upstream_ms
  local official_fmt upstream_fmt parts

  IFS='|' read -r official_code official_ms < <(check_one "$OFFICIAL_URL")
  IFS='|' read -r upstream_code upstream_ms < <(check_one "$UPSTREAM_URL")

  if [[ "$official_code" == "000" ]]; then
    parts="official DOWN"
  else
    printf -v official_fmt '%.2fs' "$official_ms"
    parts="official UP($official_code, ${official_fmt})"
  fi

  if [[ "$upstream_code" == "000" ]]; then
    parts="$parts, upstream DOWN"
  else
    printf -v upstream_fmt '%.2fs' "$upstream_ms"
    parts="$parts, upstream UP($upstream_code, ${upstream_fmt})"
  fi

  if [[ "$official_code" == "000" ]] || [[ "$upstream_code" == "000" ]]; then
    printf '%s|%s' "down" "$parts"
  else
    printf '%s|%s' "up" "$parts"
  fi
}

if (( ONCE )); then
  result="$(run_checks)"
  status="${result%%|*}"
  rest="${result#*|}"
  printf '%s\n' "$rest"
  [[ "$status" == "up" ]]
  exit $?
fi

previous=""
first=1
next_heartbeat=0
printf 'Watching Codex endpoints every %ss (Ctrl-C to stop)\n' "$INTERVAL"
if (( NTFY_ENABLED )) && [[ -n "$NTFY_TOPIC" ]]; then
  printf 'Phone heartbeat enabled every %s minute(s).\n' "$HEARTBEAT_MINUTES"
elif (( NTFY_ENABLED )); then
  printf 'Phone heartbeat is not configured; run codex-netcheck --setup-ntfy.\n' >&2
fi

while :; do
  result="$(run_checks)"
  status="${result%%|*}"
  rest="${result#*|}"
  now="$(date +%s)"

  if (( first )); then
    previous="$status"
    first=0
  elif [[ "$status" != "$previous" ]]; then
    if [[ "$status" == "down" ]]; then
      log_event "CONNECTION LOST: $rest"
      notify "Codex connection lost" "$rest"
      send_ntfy "Codex connection lost" "$rest" "warning,no_entry" "urgent" || true
      printf '\a'
    else
      log_event "connection restored: $rest"
      notify "Codex connection restored" "$rest"
      send_ntfy "Codex connection restored" "$rest" "white_check_mark,signal_strength" "high" || true
      next_heartbeat=$((now + HEARTBEAT_SECONDS))
    fi
    previous="$status"
  fi

  if [[ "$status" == "up" ]] && (( NTFY_ENABLED )) && [[ -n "$NTFY_TOPIC" ]] && (( now >= next_heartbeat )); then
    if send_ntfy "Codex connection online" "$rest. Next heartbeat expected within ${HEARTBEAT_MINUTES} minutes." "green_circle,signal_strength" "default"; then
      log_event "ntfy heartbeat sent: $rest"
    else
      log_event "NTFY HEARTBEAT FAILED: $rest"
    fi
    next_heartbeat=$((now + HEARTBEAT_SECONDS))
  fi

  if [[ "$status" == "down" ]]; then
    render "$(printf '\033[1;31m%s\033[0m' "$rest")"
  else
    render "$(printf '\033[1;32m%s\033[0m' "$rest")"
  fi

  sleep "$INTERVAL"
done
