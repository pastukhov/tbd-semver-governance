# TBD + SemVer Governance Skill

A reusable Codex skill that enforces a strict Trunk-Based Development workflow with SemVer versioning derived from Conventional Commits.

The repository contains the skill definition, governance scripts, and CI automation to keep pull requests and releases consistent.

## What This Skill Enforces

- Exactly one long-lived branch (default branch).
- All work starts from the latest default-branch commit.
- Changes are merged only through pull requests.
- Conventional Commits are mandatory.
- SemVer versioning is computed from commit history.
- Branch protection and review gates are automated for GitHub repositories.

## Repository Layout

- `SKILL.md` - skill behavior and execution workflow.
- `AGENTS.md` - contributor and agent operating rules for this repository.
- `agents/openai.yaml` - skill UI metadata.
- `scripts/` - executable governance tooling.
- `references/` - supporting policy reference.
- `.github/workflows/` - Copilot review automation and gate checks.

## Quick Start

### 1) Install local commit message validation

```bash
scripts/install_git_hooks.sh
```

### 2) Validate skill structure

```bash
python3 "$(codex home)/skills/.system/skill-creator/scripts/quick_validate.py" .
```

### 3) Apply GitHub branch protection (dry run first)

```bash
scripts/enforce_github_branch_protection.sh --dry-run
scripts/enforce_github_branch_protection.sh \
  --check copilot-review-gate \
  --required-approvals 0
```

## Script Reference

### `scripts/validate_conventional_commit.sh`
Checks a commit message file against Conventional Commits.

Example:

```bash
scripts/validate_conventional_commit.sh .git/COMMIT_EDITMSG
```

### `scripts/install_git_hooks.sh`
Installs a `commit-msg` hook that runs the validator script.

### `scripts/enforce_github_branch_protection.sh`
Configures default-branch protection using `gh api`.

Key options:

- `--repo owner/repo` - override auto-detected repository.
- `--branch branch` - override default branch.
- `--check <name>` - add required status checks (repeatable).
- `--required-approvals N` - required approving reviews (default `0`).
- `--allow-clear-checks` - explicitly allow `required_status_checks=null` when no checks are detected.
- `--dry-run` - preview payload without applying changes.

## CI Automation

- `copilot-review-request.yml` requests Copilot review on PR updates and posts `@copilot review`.
- `copilot-review-gate.yml` blocks merge until Copilot review exists and Copilot review threads are resolved.

## Recommended Development Flow

1. Create a short-lived branch from latest `origin/main`.
2. Implement and validate changes locally.
3. Open PR to `main`.
4. Resolve Copilot and CI feedback.
5. Merge only when required checks pass.

## Troubleshooting

- `gh is not authenticated`: run `gh auth login`.
- Missing required checks in auto-detection: pass explicit `--check` values.
- Commit blocked locally: fix commit message to Conventional Commit format.
