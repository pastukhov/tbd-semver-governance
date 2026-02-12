# Repository Guidelines

## Agent-Specific Instructions

- Always use `$tbd-semver-governance` for tasks related to branching, pull requests, commit policy, CI/CD, versioning, tagging, and release delivery.
- Treat `SKILL.md` as the source of truth for repository process rules.
- Preserve trunk-based flow: one long-lived default branch, short-lived task branches, PR-only merges.
- Keep post-merge SemVer tagging and tag-triggered release behavior intact when editing CI/CD.

## Project Structure & Module Organization

This repository is a Codex skill package for `tbd-semver-governance`.

- `SKILL.md`: main skill contract and workflow rules.
- `agents/openai.yaml`: UI metadata for skill discovery/invocation.
- `scripts/`: executable governance tooling:
  - `validate_conventional_commit.sh`
  - `install_git_hooks.sh`
  - `enforce_github_branch_protection.sh`
- `references/ci_cd_policy.md`: policy reference used by the skill.
- `.github/workflows/`: automation for Copilot review request and review gate checks.

## Build, Test, and Development Commands

Use these commands from repository root:

- `scripts/install_git_hooks.sh`: install local `commit-msg` hook.
- `scripts/validate_conventional_commit.sh .git/COMMIT_EDITMSG`: validate a commit message file.
- `scripts/enforce_github_branch_protection.sh --dry-run`: preview branch protection payload.
- `scripts/enforce_github_branch_protection.sh --check copilot-review-gate --required-approvals 0`: apply protection for this repo model.
- `python3 /home/artem/.codex/skills/.system/skill-creator/scripts/quick_validate.py .`: validate skill structure and metadata.

## Coding Style & Naming Conventions

- Shell scripts must use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Prefer small, composable functions (`require_cmd`, `parse_repo_from_origin` style).
- Keep file names lowercase with hyphens/underscores; keep skill names hyphen-case.
- Use clear CLI flags and explicit error messages for invalid input.

## Testing Guidelines

- Run `bash -n scripts/*.sh` for shell syntax checks.
- Run `quick_validate.py` before opening a PR.
- For behavior changes, include at least one `--dry-run` example in PR description.
- If CI check names change, verify `copilot-review-gate` and protection checks still match.

## Commit & Pull Request Guidelines

- Follow Conventional Commits (`feat:`, `fix:`, `chore:`; use `!`/`BREAKING CHANGE:` for major bumps).
- Do not push directly to `main`; use short-lived branches from latest `origin/main`.
- Open PRs with concise summary, risk notes, and commands used for verification.
- Resolve all Copilot review threads before merge.
- Merge only when required checks are green and branch protection allows it.
