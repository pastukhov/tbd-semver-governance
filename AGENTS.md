# AGENTS.md

## Required Skill

- Always use `$tbd-semver-governance` for any task in this repository related to development workflow, branching, pull requests, commit policy, CI/CD, versioning, tagging, and release delivery.

## Repository Governance

- Treat `SKILL.md` in the repository root as the source of truth for process rules.
- Enforce Conventional Commits for all commits.
- Keep exactly one long-lived branch: the default branch.
- Start each task from the latest default-branch commit, use a short-lived branch, open PR, and merge only after successful required checks.
- Ensure post-merge SemVer tagging and tag-triggered release pipeline behavior remain intact when changing CI/CD configuration.

## Local Enforcement

- Install local commit message validation with:
  - `scripts/install_git_hooks.sh`
- Validate commit messages with:
  - `scripts/validate_conventional_commit.sh <commit-message-file>`
