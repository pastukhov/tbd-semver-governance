# TBD + SemVer CI/CD Policy

## Purpose

Apply one long-lived default branch and short-lived task branches with strict quality gates and automated SemVer tagging.

## Branching

1. Keep exactly one long-lived branch: default branch.
2. Create every task branch from the latest commit on default branch.
3. Delete task branch immediately after merge.

## Pull Requests

1. Open PR from task branch into default branch.
2. Require all configured checks to pass before merge.
3. Prevent any bypass merge path for failing checks.

## Commit Messages

1. Require Conventional Commits for all commits.
2. Enforce locally via `commit-msg` hook.
3. Enforce in CI as defense-in-depth.

## Versioning and Release

1. After merge to default branch, run a versioning pipeline.
2. Compute next SemVer from Conventional Commits since the last tag.
3. Create tag on the commit where version is computed (normally merge commit).
4. Trigger release pipeline on new tag.
5. Build release artifacts (for example image, manifests).
6. Publish artifacts (for example registry push, cluster apply).

## Recommended Branch Protection

1. Restrict direct pushes to default branch.
2. Require pull requests for all changes.
3. Require status checks to pass before merge.
4. Require branches to be up to date before merge.
5. Restrict merge methods to repository-approved strategy.
6. Allow automatic deletion of head branch after merge.

## Automatic GitHub Setup

1. Ensure `git`, `python3`, and GitHub CLI `gh` are installed.
2. Ensure `gh` is authenticated (`gh auth login`) with repository permissions sufficient to manage branch protection.
3. Apply protection with `scripts/enforce_github_branch_protection.sh`.
4. Let the script auto-detect `owner/repo` from `origin` and default branch from GitHub.
5. Let the script auto-detect required checks from latest default-branch check runs, or pass checks explicitly with repeated `--check`.
6. Set approvals policy explicitly with `--required-approvals` (use `0` for no manual approvals when Copilot gate is used).
7. Run with `--dry-run` first when validating a new repository policy.

## CI Check Suggestions

1. Run unit tests.
2. Run integration or contract tests if present.
3. Run lint and static analysis.
4. Validate commit messages in PR history.
5. Optionally validate that branch was created from current default head when policy requires strict freshness.
