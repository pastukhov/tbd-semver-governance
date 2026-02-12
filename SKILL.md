---
name: tbd-semver-governance
description: Governance workflow for repositories that use Trunk-Based Development with exactly one long-lived default branch and SemVer releases derived from Conventional Commits. Use when planning or implementing branch strategy, PR policy, CI/CD gates, release tagging, commit rules, and local commit-message enforcement for this model.
---

# TBD + SemVer Governance

## Overview

Apply a strict trunk-based workflow with one long-lived default branch and gated releases.
Treat every repository change as a short-lived branch plus pull request that passes all checks.

## Non-Negotiable Rules

Enforce these rules in every recommendation and implementation:

1. Keep exactly one long-lived branch: the repository default branch.
2. Start each task branch from the latest commit on the default branch.
3. Open a pull request from the task branch into the default branch.
4. Run all required tests on the pull request.
5. Block merge if any required check fails.
6. Write all commit messages in Conventional Commits format.
7. After PR merge, run versioning pipeline to compute SemVer from Conventional Commits and create a tag on the merge commit.
8. Delete the task branch after successful merge.
9. On tag creation, run a release pipeline to build artifacts (for example container image and Kubernetes manifests).
10. Publish build outputs to target systems (for example image registry and Kubernetes cluster).
11. Install local commit-message checks to reject non-Conventional-Commit messages before they enter history.

## Standard Agent Workflow

Use this sequence when executing work in a governed repository:

1. Detect whether `origin` points to GitHub.
2. If repository is on GitHub, run `scripts/enforce_github_branch_protection.sh` before starting implementation.
3. Detect default branch and fetch latest state.
4. Create a short-lived branch from `origin/<default-branch>` head.
5. Implement changes and tests in that branch only.
6. Validate locally (unit/integration/lint as repository defines).
7. Ensure every new commit message follows Conventional Commits.
8. Push branch and open PR to default branch.
9. Confirm CI checks are green before merge recommendation.
10. Merge with repository-approved strategy.
11. Delete merged branch.
12. Verify version-tag pipeline and release pipeline trigger and complete.

If default branch is unknown, determine it first and avoid assumptions.

## Conventional Commits and SemVer Mapping

Use this release mapping:

1. `feat:` increments MINOR.
2. `fix:` increments PATCH.
3. `!` marker or `BREAKING CHANGE:` footer increments MAJOR.
4. Commits that do not affect public behavior (for example `chore`, `docs`, `test`) do not increment by themselves unless repository policy says otherwise.

If multiple commit types exist since the last tag, apply highest precedence: MAJOR > MINOR > PATCH.

## Local Enforcement Resources

Use bundled scripts for commit-message enforcement:

1. Run `scripts/install_git_hooks.sh` from repository root to install `commit-msg` hook.
2. The hook runs `scripts/validate_conventional_commit.sh` and blocks invalid messages.
3. For GitHub repositories, run `scripts/enforce_github_branch_protection.sh` to apply required branch protection automatically.

For CI guidance and branch protection defaults, read `references/ci_cd_policy.md`.
