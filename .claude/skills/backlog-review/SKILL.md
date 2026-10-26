---
name: backlog-review
description: Survey docs/backlog/, docs/plans/, docs/adr/, and open GitHub issues in johnofsydney/lester to produce two lists — bigger potential projects, and small fast pieces that can run with minimal oversight. Use when the user asks to "review the backlog", "what should I work on", "give me project ideas", or wants a fresh prioritized list of work from issues/backlog.
---

# Lester backlog review

Produces two lists from a survey of current open work:

1. **Potential projects** — bigger pieces of work that advance the project.
2. **Small fast pieces** — scoped, low-oversight work that can be picked up and run with
   minimal back-and-forth.

## Gathering (run these in parallel, one message, no prior filtering)

1. Invoke the `project-status` skill — it shows what's already in progress / designed /
   completed, which determines whether something belongs on the list at all or is already moving.
2. List backlog notes: `ls /Users/john/Projects/lester/docs/backlog/`
3. List open GitHub issues with labels:
   `gh issue list --limit 100 --state open --json number,title,labels,createdAt --repo johnofsydney/lester`
4. List existing design docs: `ls /Users/john/Projects/lester/docs/plans/ /Users/john/Projects/lester/docs/adr/`

Don't read every backlog file in full — titles are usually self-explanatory. Only open a
backlog file or issue body when its title is ambiguous enough to misclassify.

## Classifying

**Bigger projects** — anything that:
- has no design doc yet and needs one, or has a design doc but zero commits (e.g. "designed,
  not built" in PROJECT_STATUS.md)
- is tagged `needs-discussion` / `discussion-starter` on GitHub (product/design decision needed
  before work starts)
- is a new data source, new architecture/infra decision, or a multi-step ingestion pipeline
- spans multiple files/services or touches the domain model

**Small fast pieces** — anything that:
- is tagged `ready-to-build` on GitHub, or is a narrowly-described UI/display bug
- is a backlog note describing one bounded fix, one dead-code removal, or one missing spec
- can be fully scoped from its title/description alone, no product decision required

Cross-check against open PRs and recent merges (`gh pr list`, `git log --oneline -10`) before
listing anything — PROJECT_STATUS.md can go stale (e.g. a PR merges but the status doc still
says "draft, open for review"); flag any such staleness to the user rather than silently
trusting the doc.

Flag likely-duplicate issues (e.g. two issues describing the same root cause under different
numbers) in the small-pieces list rather than listing both as separate work.

## Output

Two markdown lists in chat, one line per item, grouped by rough theme (ingestion, platform/
architecture, UI/display fixes, etc.) within each list. Link GitHub issue numbers and backlog
file names so the user can jump straight to the source. Keep it scannable — this is a planning
aid, not a report to be filed anywhere.

Don't write the output to a file unless the user asks; it's a point-in-time survey, not a
document to maintain (that's what PROJECT_STATUS.md is for).
