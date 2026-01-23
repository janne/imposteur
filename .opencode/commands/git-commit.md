---
name: git-commit
description: Create a git commit with a generated message and push
---

Create a git commit in the current repository with a generated message and
push it to the remote.

Steps
- Run `git status -sb` to confirm the working tree.
- Review changes with `git diff` and `git diff --staged`.
- Stage all changes with `git add -A`.
- Create the commit with a generated message (no input argument).
- Push to the remote with `git push`.
- Run `git status -sb` to confirm a clean tree.

Rules
- Do not amend existing commits.
- Do not commit files that contain secrets.
- If there are no changes to commit, explain and stop.
