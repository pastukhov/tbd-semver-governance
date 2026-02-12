#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <commit-message-file>" >&2
  exit 2
fi

msg_file="$1"
if [[ ! -f "$msg_file" ]]; then
  echo "commit message file not found: $msg_file" >&2
  exit 2
fi

first_line="$(head -n1 "$msg_file" | tr -d '\r')"

# Conventional Commits core pattern:
# type(scope)!: subject
# type!: subject
# type: subject
# Allowed lowercase types below can be adjusted if repository policy differs.
pattern='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9._/-]+\))?(!)?: .+'

if [[ "$first_line" =~ $pattern ]]; then
  exit 0
fi

echo "invalid Conventional Commit message:" >&2
echo "  $first_line" >&2
echo >&2
echo "expected format: type(scope): subject" >&2
echo "examples:" >&2
echo "  feat(api): add pagination support" >&2
echo "  fix: handle nil pointer in parser" >&2
echo "  refactor!: remove legacy v1 endpoint" >&2
echo >&2
echo "allowed types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test" >&2
exit 1
