---
name: merge-to-staging
description: Merge the current feature branch into staging and push it to origin. Use when the user wants to deploy/promote their current branch to staging, e.g. "merge this to staging", "push to staging", "get this onto staging".
---

# Merge to staging

Promotes the current feature branch onto the `staging` integration branch and pushes it.
Mirrors the manual process: switch to `staging`, merge the feature branch in with a real
merge commit, push, switch back.

## Steps

1. Capture the current branch name — this is the branch being merged in.
   ```
   git branch --show-current
   ```
   If this is already `staging` or `main`, stop and ask the user which branch they meant to merge.

2. Check for uncommitted changes with `git status`. If there are any, stop and ask the user
   whether to commit, stash, or abort — never carry uncommitted work across a branch switch.

3. Fetch and fast-forward local tracking branches:
   ```
   git fetch origin
   ```

4. Switch to `staging` and fast-forward it to `origin/staging`:
   ```
   git checkout staging
   git merge --ff-only origin/staging
   ```
   If the ff-only merge fails, stop — local `staging` has diverged from origin in a way that
   needs human attention.

5. Merge the feature branch into `staging` with a real merge commit (no `--squash`, no
   `--ff-only` here — history should show the merge, matching the existing staging log):
   ```
   git merge --no-ff <feature-branch> -m "Merge branch '<feature-branch>' into staging"
   ```
   If there's a conflict, stop and report it — do not resolve conflicts automatically;
   let the user decide.

6. Push staging:
   ```
   git push origin staging
   ```

7. Switch back to the original feature branch:
   ```
   git checkout <feature-branch>
   ```

8. Report what happened: the merge commit SHA, and confirmation the push succeeded.

## Notes

- This project always uses real merge commits, never squash merges (see repo conventions) —
  step 5's `--no-ff` is required, not optional.
- Merging into `staging` does not require the feature branch's PR to be merged into `main`
  first — `staging` is a pre-release integration branch and commonly carries in-progress work.
- If `git push origin staging` fails (e.g. non-fast-forward because someone else pushed),
  stop and report it rather than force-pushing.
