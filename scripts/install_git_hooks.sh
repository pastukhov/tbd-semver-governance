#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "run this script inside a git repository" >&2
  exit 1
fi

hook_dir="$repo_root/.git/hooks"
hook_path="$hook_dir/commit-msg"
validator_rel="scripts/validate_conventional_commit.sh"
validator_abs="$repo_root/$validator_rel"

if [[ ! -x "$validator_abs" ]]; then
  chmod +x "$validator_abs"
fi

mkdir -p "$hook_dir"
cat > "$hook_path" <<HOOK
#!/usr/bin/env bash
set -euo pipefail

"$validator_abs" "\$1"
HOOK

chmod +x "$hook_path"
echo "installed commit-msg hook: $hook_path"
echo "validator: $validator_abs"
