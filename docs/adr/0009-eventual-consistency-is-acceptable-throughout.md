# Join the Dots is a reporting service; eventual consistency is acceptable throughout

**Status:** Accepted

## Context

ADR-0008 noted, in passing, that `Transfer#amount` lagging its `IndividualTransaction` children by
minutes (and being compared with integer truncation before it's corrected) is fine, not a bug to
fix. That observation generalises: Join the Dots is a reporting and aggregation tool over
historical/periodically-refreshed public data (AEC disclosures, AusTender releases, ACNC filings,
OpenAustralia parliamentary records). It *is* a system of record in the sense that it stores and
serves this data — but it is never the *first-class* system of record for any of it. AusTender
remains the authoritative source for government contracts; nobody treats Join the Dots as the
canonical list of lobbyists, donors, or politicians. Every fact here is a copy, ingested from
somewhere else's system of record, on somewhere else's publication schedule. Nobody's money moves
through this app; it describes money that has already moved, as reported by someone else.

## Decision

Eventual consistency is an acceptable default everywhere in this codebase, not just for `Transfer`
amounts. A derived value (a cached rollup, a `cached_data` snapshot, a background-recomputed
aggregate) doesn't need to be correct synchronously with the write that invalidated it. It's fine
for it to become correct shortly afterwards via a background job, and fine for "shortly" to mean
seconds to minutes rather than milliseconds.

This isn't a new pattern — it's already how `CachedMethods#cached` works. Person/Group's
`cached_data` jsonb is treated as fresh for up to a week; when it's stale, the controller enqueues
`BuildPersonCachedDataJob`/`BuildGroupCachedDataJob` and shows a "please refresh" page rather than
blocking on a synchronous rebuild. That's the same trade-off as `Transfer#amount`, just with a
longer accepted lag. This ADR generalises the pattern both already use, rather than introducing it.

**Scope: derived/background-recomputed data only, not admin-triggered writes.** Actions like
`Admin::Groups#perform_merge` or `Admin::People::ExplodePerson` change the shape of the graph
itself, at a human's direct instruction — those should behave as synchronous, consistent writes.
This ADR licenses lag for background recomputation of derived aggregates; it says nothing about,
and doesn't relax, the consistency expected of a deliberate admin action.

This doesn't mean sloppiness is free:

- **Shorten the lag where it's cheap to do so.** Preferring a fast background job over a slow one,
  or a synchronous update over an async one, is still worth doing when it doesn't cost real
  complexity — the point is that lag is an acceptable trade-off to make, not a target to maximise.
- **The eventual part still has to be true.** "Eventually correct" requires the recompute path to
  actually run and actually converge — a job that's silently failing, or a comparison that can
  permanently mask small drift (as flagged for `Transfers::RefreshSingleTransferAmountJob` in
  ADR-0008), is a real bug, not covered by this ADR. This ADR licenses *lag before* correctness, not
  correctness that never arrives.
- **Primary/source data is a different category.** This applies to *derived* data — caches,
  rollups, aggregates. It says nothing about the raw ingested data itself (`IndividualTransaction`,
  `Person#open_australia_data`, `Person#council_election_data`, and similar) being allowed to be
  wrong or stale in the same way; freshness/correctness of the source data is a separate, per-source
  concern (see e.g. ADR-0001, ADR-0006) unaffected by this decision.

## Consequence

When a future decision involves choosing between "update this synchronously, at some complexity
cost" and "update this in the background, accepting a short window of staleness," the default
answer is the background job, and that shouldn't need re-litigating each time by pointing at
`Transfer` as precedent — this ADR is that precedent, generalised.
