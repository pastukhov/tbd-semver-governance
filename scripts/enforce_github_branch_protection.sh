#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 [--repo owner/repo] [--branch branch] [--check check-name]... [--required-approvals N] [--allow-clear-checks] [--dry-run]

Options:
  --repo      GitHub repository in owner/repo format. If omitted, detect from git origin.
  --branch    Branch to protect. If omitted, detect default branch from GitHub.
  --check     Required status check name. Repeatable.
  --required-approvals
              Number of required approving reviews. Default: 0.
  --allow-clear-checks
              Allow clearing required_status_checks when no checks were provided and none were auto-detected.
  --dry-run   Print detected values and payload without applying changes.
  -h,--help   Show this help.

Behavior:
  - Apply branch protection to require pull requests and review gates.
  - Configure required status checks only when provided via --check or auto-detected.
  - Require branches to be up to date before merge.
  - Require N approving reviews (set by --required-approvals) and conversation resolution.
  - Enforce rules for admins.
  - Enable delete_branch_on_merge at repository level.
USAGE
}

repo=""
branch=""
dry_run=false
checks=()
allow_clear_checks=false
required_approvals=0

require_flag_value() {
  local flag="$1"
  local count="$2"
  local value="${3-}"

  if [[ "$count" -lt 2 || -z "$value" || "$value" == -* ]]; then
    echo "missing value for $flag" >&2
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      require_flag_value "--repo" "$#" "${2-}"
      repo="$2"
      shift 2
      ;;
    --branch)
      require_flag_value "--branch" "$#" "${2-}"
      branch="$2"
      shift 2
      ;;
    --check)
      require_flag_value "--check" "$#" "${2-}"
      checks+=("$2")
      shift 2
      ;;
    --required-approvals)
      require_flag_value "--required-approvals" "$#" "${2-}"
      if [[ ! "$2" =~ ^[0-9]+$ ]]; then
        echo "invalid value for --required-approvals: $2" >&2
        exit 2
      fi
      required_approvals="$2"
      shift 2
      ;;
    --allow-clear-checks)
      allow_clear_checks=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required command not found: $1" >&2
    exit 1
  }
}

parse_repo_from_origin() {
  local url
  local repo_path
  url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$url" ]]; then
    return 1
  fi

  if [[ "$url" =~ ^git@github\.com:(.+)$ ]]; then
    repo_path="${BASH_REMATCH[1]}"
    repo_path="${repo_path%.git}"
    repo_path="${repo_path%/}"
    echo "$repo_path"
    return 0
  fi

  if [[ "$url" =~ ^ssh://git@github\.com[:/](.+)$ ]]; then
    repo_path="${BASH_REMATCH[1]}"
    repo_path="${repo_path%.git}"
    repo_path="${repo_path%/}"
    echo "$repo_path"
    return 0
  fi

  if [[ "$url" =~ ^https://github\.com/(.+)$ ]]; then
    repo_path="${BASH_REMATCH[1]}"
    repo_path="${repo_path%.git}"
    repo_path="${repo_path%/}"
    echo "$repo_path"
    return 0
  fi

  return 1
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

url_encode() {
  python3 - "$1" <<'PY'
import sys
import urllib.parse

print(urllib.parse.quote(sys.argv[1], safe=""))
PY
}

build_checks_json() {
  local out=""
  local name

  for name in "$@"; do
    [[ -n "$name" ]] || continue
    if [[ -n "$out" ]]; then
      out+=","
    fi
    out+="{\"context\":$(json_escape "$name")}"
  done

  printf '[%s]' "$out"
}

require_cmd git
require_cmd python3

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "run inside a git repository" >&2
  exit 1
fi
cd "$repo_root"

if [[ -z "$repo" ]]; then
  repo="$(parse_repo_from_origin || true)"
fi

if [[ -z "$repo" ]]; then
  echo "unable to detect GitHub repository from origin; pass --repo owner/repo" >&2
  exit 1
fi

need_gh=false
if [[ -z "$branch" || ${#checks[@]} -eq 0 || "$dry_run" == false ]]; then
  need_gh=true
fi

if $need_gh; then
  require_cmd gh
  if ! gh auth status >/dev/null 2>&1; then
    echo "gh is not authenticated. Run: gh auth login" >&2
    exit 1
  fi
fi

if [[ -z "$branch" ]]; then
  branch="$(gh repo view "$repo" --json defaultBranchRef --jq '.defaultBranchRef.name')"
fi

encoded_branch="$(url_encode "$branch")"

if [[ ${#checks[@]} -eq 0 ]]; then
  if ! head_sha="$(gh api "repos/$repo/commits/$encoded_branch" --jq '.sha')"; then
    echo "failed to retrieve head commit for $repo:$branch" >&2
    exit 1
  fi

  check_runs_ok=true
  detected_raw="$(gh api "repos/$repo/commits/$head_sha/check-runs" --jq '.check_runs[].name' 2>/dev/null)" || check_runs_ok=false

  status_ok=true
  status_raw="$(gh api "repos/$repo/commits/$head_sha/status" --jq '.statuses[].context' 2>/dev/null)" || status_ok=false

  if ! $check_runs_ok && ! $status_ok; then
    echo "failed to retrieve both check runs and commit statuses for commit $head_sha from $repo" >&2
    exit 1
  fi

  mapfile -t detected <<<"$(printf '%s\n%s\n' "$detected_raw" "$status_raw" | sed '/^$/d' | sort -u)"
  checks=("${detected[@]}")
fi

has_required_checks=true
if [[ ${#checks[@]} -eq 0 ]]; then
  if ! $allow_clear_checks; then
    echo "no required checks were provided and none were auto-detected." >&2
    echo "refusing to clear required_status_checks by default." >&2
    echo "pass --allow-clear-checks to allow required_status_checks=null explicitly." >&2
    exit 1
  fi
  has_required_checks=false
fi

if payload_file="$(mktemp -t enforce_github_branch_protection.XXXXXX 2>/dev/null)"; then
  :
else
  payload_file="$(mktemp "${TMPDIR:-/tmp}/enforce_github_branch_protection.XXXXXX")"
fi

trap 'rm -f "$payload_file"' EXIT
checks_json="$(build_checks_json "${checks[@]}")"

if $has_required_checks; then
  required_status_checks_block=$(cat <<JSON
  "required_status_checks": {
    "strict": true,
    "checks": $checks_json
  },
JSON
)
else
  required_status_checks_block='  "required_status_checks": null,'
fi

cat > "$payload_file" <<JSON
{
${required_status_checks_block}
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": $required_approvals
  },
  "restrictions": null,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_linear_history": false,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON

if $dry_run; then
  echo "repo: $repo"
  echo "branch: $branch"
  if $has_required_checks; then
    echo "required checks:"
    for c in "${checks[@]}"; do
      echo "- $c"
    done
  else
    echo "required checks: none detected (required_status_checks will be null because --allow-clear-checks is set)"
  fi
  echo
  echo "payload:"
  cat "$payload_file"
  exit 0
fi

gh api --method PUT "repos/$repo/branches/$encoded_branch/protection" --input "$payload_file" >/dev/null

gh api --method PATCH "repos/$repo" -f delete_branch_on_merge=true >/dev/null

echo "branch protection updated for $repo:$branch"
if $has_required_checks; then
  echo "required checks: ${checks[*]}"
else
  echo "required checks: none configured (set them later with --check ...)"
fi
echo "repository setting enabled: delete_branch_on_merge=true"
