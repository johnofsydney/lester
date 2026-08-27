---
name: normalize-issue-titles
description: Ensure GitHub issue titles in this repo follow the consistent "LES-<issue number>: Description" format. Use when the user wants issue titles normalized/cleaned up, asks to fix an issue's title, or wants all issues checked for naming consistency.
---

# Normalize issue titles

Keeps GitHub issue titles in `johnofsydney/lester` consistent with the required format:

```
LES-<github issue number>: Description of the issue
```

## Steps

1. Determine scope: a single issue number given by the user, or "all issues" (open, or
   open+closed if the user says so). Use `gh issue list` / `gh issue view` (or the GitHub
   MCP tools) to fetch the current title(s) and number(s).

2. For each issue, check whether its title already matches the format exactly:
   ```
   LES-<number>: <description>
   ```
   where `<number>` is that issue's own GitHub issue number (not any other number that may
   already appear in the title).

3. If it already matches — leave it untouched. Don't rewrite for cosmetic reasons (casing,
   wording) if the `LES-<number>: ` prefix is already correct.

4. If it does not match, reformat it:
   - Strip any existing `LES-...:`, `#<number>:`, or bare `<number>:` prefix the title may
     already have, plus surrounding whitespace, to recover the underlying description.
   - Prepend `LES-<github issue number>: ` to that description.
   - Preserve the description's original wording/casing — only the prefix changes.
   - Update the issue title via `gh issue edit <number> --title "LES-<number>: <description>"`
     (or the equivalent MCP `issue_write` call).

5. Report a short summary: how many issues were checked, how many were already compliant,
   and the before/after title for each one that was changed.

## Notes

- The issue number in the prefix is always that issue's own number — never renumber or
  reorder issues.
- This only touches titles. Never edit issue bodies, labels, or state as part of this skill.
- If bulk-editing many issues, confirm the full list of proposed renames with the user before
  applying them, since title edits on GitHub are visible to collaborators.
