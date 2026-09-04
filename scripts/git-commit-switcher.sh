#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: git-commit-switcher [options]

Update user.name and user.email for the current Git repository only.
With no options, the command prompts for both values.

Options:
  -n, --name NAME      Git commit author name
  -e, --email EMAIL    Git commit author email
  -s, --show           Show the repository's local Git identity
  -h, --help           Show this help

Examples:
  git-commit-switcher
  git-commit-switcher --name "Jane Doe" --email "jane@example.com"
  git-commit-switcher --show
EOF
}

require_value() {
  if (( $# < 2 )) || [[ -z "$2" ]]; then
    printf 'Option %s requires a value.\n' "$1" >&2
    exit 2
  fi
}

git_name=""
git_email=""
show_only=0

while (( $# > 0 )); do
  case "$1" in
    -n|--name)
      require_value "$@"
      git_name="$2"
      shift
      ;;
    -e|--email)
      require_value "$@"
      git_email="$2"
      shift
      ;;
    -s|--show)
      show_only=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ! command -v git >/dev/null 2>&1; then
  printf 'Git is required but was not found.\n' >&2
  exit 1
fi

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  printf 'Run this command inside a Git repository.\n' >&2
  exit 1
fi

local_name="$(git config --local --get user.name 2>/dev/null || true)"
local_email="$(git config --local --get user.email 2>/dev/null || true)"

if (( show_only )); then
  printf 'Repository: %s\n' "$repo_root"
  printf 'user.name:  %s\n' "${local_name:-<not set locally>}"
  printf 'user.email: %s\n' "${local_email:-<not set locally>}"
  exit 0
fi

default_name="${local_name:-$(git config --get user.name 2>/dev/null || true)}"
default_email="${local_email:-$(git config --get user.email 2>/dev/null || true)}"

if [[ -z "$git_name" ]]; then
  read -r -p "Git user name${default_name:+ [$default_name]}: " entered_name
  git_name="${entered_name:-$default_name}"
fi

if [[ -z "$git_email" ]]; then
  read -r -p "Git user email${default_email:+ [$default_email]}: " entered_email
  git_email="${entered_email:-$default_email}"
fi

if [[ -z "$git_name" ]]; then
  printf 'Git user name cannot be empty.\n' >&2
  exit 2
fi

if [[ -z "$git_email" || "$git_email" != *@* ]]; then
  printf 'Enter a valid Git user email.\n' >&2
  exit 2
fi

git config --local user.name "$git_name"
git config --local user.email "$git_email"

printf 'Updated local Git identity for %s\n' "$repo_root"
printf 'user.name:  %s\n' "$(git config --local --get user.name)"
printf 'user.email: %s\n' "$(git config --local --get user.email)"
