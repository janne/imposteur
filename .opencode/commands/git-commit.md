---
name: git-commit
description: Create a git commit with a message
args:
  message:
    description: Commit message text
    required: true
---

Create a git commit in the current repository using the provided message.

Steps
- Run `git status -sb` to confirm the working tree.
- Review changes with `git diff` and `git diff --staged`.
- Stage all changes with `git add -A`.
- Create the commit with `git commit -m "{{message}}"`.
- Run `git status -sb` to confirm a clean tree.

Rules
- Do not amend existing commits.
- Do not push to remotes.
- Do not commit files that contain secrets.
- If there are no changes to commit, explain and stop.
