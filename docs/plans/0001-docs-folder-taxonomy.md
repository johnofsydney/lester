# Docs folder taxonomy: one root, five purpose-specific subfolders

**Status:** Proposed

## Problem

`docs/` and `notes/` both existed as top-level doc folders, started at different times with a
naive view of how these docs would be used. `docs/` had structure (`adr/`, `agents/`); `notes/`
was a grab-bag of design docs, plans, a runbook, and an ops note, with inconsistent filenames —
only one of its nine files followed any stated naming convention.

## Decision

Consolidate on a single top-level root, `docs/`, with five subfolders, each with a distinct
purpose, naming rule, and lifecycle. This doc is itself the first entry in the new `docs/plans/`
sequence — using the numbering rule it defines.

| Folder | Purpose | Naming | Status field | Lifecycle |
|---|---|---|---|---|
| `docs/adr/` | Settled decision record — short, past-tense, "we chose X over Y because Z" | `NNNN-slug.md`, sequential | Yes: `Accepted` / `Superseded by ADR-NNNN` | Immutable once merged to main |
| `docs/plans/` | Detailed, forward-looking design/build doc for committed work | `NNNN-slug.md`, sequential (own counter, separate from `adr/`) | Yes: `Proposed` / `In Progress` / `Implemented` | Kept permanently as historical record, even once implemented — never deleted |
| `docs/backlog/` | One file per not-yet-committed idea/future-work item | `slug.md`, no number | Optional, e.g. `Idea` / `Ready to pick up` | Deleted once promoted — the numbered plan or GitHub issue becomes the record |
| `docs/runbooks/` | Operational "what do I do when X happens" procedures | `slug.md`, no number | None | Living document, edited in place as the procedure changes |
| `docs/agents/` | Process docs read by Claude/skills (existing — unchanged) | `slug.md`, no number | None | Living document |

`CONTEXT.md` stays at the repo root (established single-context-repo convention per
`docs/agents/domain.md`) — not moved into a `docs/` subfolder.

### Why ADR and plan are separate categories, not a spectrum

An ADR is retrospective and short: a settled call, stated once, essentially immutable after
merge — its job is to save a future reader from re-litigating a decision already made. A plan is
prospective and detailed: an approach being worked through, with a status that moves as the work
progresses. They can coexist for the same piece of work — the plan holds the "how we built it"
detail, and if a genuinely reusable decision falls out of it, that gets distilled into its own
short ADR.

### Why `backlog/` is one folder, not split into "ideas" vs "backlog"

Considered splitting speculative material by how well-formed it is (a vaguer `ideas/` vs a more
concrete `backlog/`), but rejected it: "how baked is this idea" is a spectrum, not a category —
there's no crisp rule for which side of the line a given file sits on, so every new file would
cause folder-choice hesitation, and ideas would need constant "promotion" between the two folders
as they firmed up. That's churn a numbered system doesn't have, because `adr/` vs `plans/` really
are structurally different content. One `docs/backlog/` folder instead; maturity is visible in
the file itself (an optional `Status:` line, or just how developed the writeup is).

## Sequential numbering + clash-resolution rule (shared by `adr/` and `plans/`)

- Next number = highest existing `NNNN` in that specific folder + 1, zero-padded to 4 digits.
  Each folder has its own independent counter.
- A number is only considered "claimed" once its file is merged to main.
- If two branches independently claim the same number, **whichever branch merges second
  renumbers its file** (and any in-repo cross-references to it) to the next free number, before
  merging.
- Never renumber a file that's already on main — same immutability spirit as the existing "never
  edit an already-run migration" rule (see `CODING_STANDARDS.md`).

## Backlog → promotion flow

A `docs/backlog/slug.md` idea, once someone commits to doing it, becomes either a numbered
`docs/plans/NNNN-slug.md` or a GitHub issue. Both remain valid entry points for future work — the
repo-file backlog is the primary mechanism, GitHub issues a secondary one used occasionally (e.g.
away from the primary laptop). Once promoted, the original backlog file is deleted; the plan or
issue is now the record.

## Scope

At the time this taxonomy was adopted, it governed *new* docs only — `notes/`'s existing nine
files were deliberately left untouched, migration being a separate, later task. That migration has
since happened (see Follow-up below); this section is kept as a record of the original,
narrower scope.

## Follow-up (not covered by this doc)

All three items below have since been completed:

- ~~Migrate `notes/`'s existing files into the new `docs/` subfolders.~~ Done — `notes/` no longer
  exists; its 9 files are now under `docs/plans/`, `docs/runbooks/`, and split into `docs/backlog/`.
- ~~Correct `CLAUDE.md`'s issue-tracker section, which currently overstates GitHub issues as *the*
  tracker.~~ Done — it now describes `docs/backlog/` as primary, GitHub issues as secondary.
- ~~Retrofit `Status:` fields onto the 5 existing ADRs.~~ Done — all 5 now carry `Status: Accepted`.
