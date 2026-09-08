---
name: project-status
description: View or update the consolidated Lester project status doc (ongoing work, designed-not-built, completed) with checkboxes. Use when the user asks "what's the status", "what am I working on", "show project status", or wants to mark something done/in-progress in the Lester project.
---

# Lester project status

The status doc lives at a fixed absolute path, independent of which worktree or directory
the current session is rooted in:

    /Users/john/Projects/lester/PROJECT_STATUS.md

It is intentionally untracked (gitignored) — a personal scratchpad with structure, not
project documentation for others.

## Viewing

Every time this skill is invoked, do both of the following — not one or the other:

1. Read the markdown file directly and show it to the user in-chat (rendered, not dumped raw).
2. Regenerate and open the HTML rendering, so the browser view is always current too — the
   markdown stays the single source of truth, the HTML is disposable output regenerated fresh
   each time:

       ruby /Users/john/Projects/lester/.claude/skills/project-status/render.rb && open /Users/john/Projects/lester/PROJECT_STATUS.html

`render.rb` parses `## ` sections and `- [ ]`/`- [x]` items (with indented detail lines) into
styled cards with per-section progress bars, light/dark aware. It has no state of its own —
don't hand-edit `PROJECT_STATUS.html`; edit the markdown and re-run.

### Status pills

An unchecked item's first line can start with a `{tag}` marker to render a colored status pill
in the HTML view (checked items always render a green "Complete" pill instead, regardless of
tag). Supported tags — pick the one that matches reality, don't invent new ones without adding
them to `PILLS` in `render.rb`:

- `{in-progress}` — active work underway
- `{waiting-on-verification}` — implementation done, waiting on manual testing/review before merge
- `{investigating}` — still at the exploration/investigation stage, no build yet
- `{designed}` — design done, build not started
- `{not-started}` — not yet scoped or planned
- `{blocked}` — stalled on something external

Example: `- [ ] {waiting-on-verification} **Thing** — detail...`

## Updating

- Check a box (`- [ ]` → `- [x]`) when the user confirms something is complete, or when you
  independently verify completion (e.g. a PR merged, a branch's work landed on main) — confirm
  with the user first if it's not obvious from context.
- Add new lines under the right section (`In progress`, `Designed, not built`, `Completed`)
  when new work starts or is proposed. Keep entries short — one line + optional detail line,
  matching the existing style.
- Move a checked item into `Completed` rather than leaving finished work under `In progress`.
- Don't over-formalize: no need to ask permission for small edits (checking a box, tweaking
  wording) — just do it and mention what changed. Do check in before large restructuring.
- This file has no bearing on git commits — never suggest committing it.
