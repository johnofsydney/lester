# State Branch Membership start_date is wrongly set to the person's federal-entry date

`OpenAustralia::Interpretation::RecordMembershipsAndPositions#record_state_branch` (and
`#record_minor_party`, same pattern) records a State Branch/Minor Party Membership's `start_date`
as `affiliation.start_date` — which is `ResolvePartyAffiliations`' `parse_date(first_term['entered_house'])`,
i.e. **the date the person first entered federal Parliament**, not the date they joined their
party's state branch.

That's the same value used for the *Federal* Branch Membership, where it's correct — "Federal
Parliamentary Party Member" genuinely does begin the day someone becomes a federal MP for that
party. It's wrong for the State Branch: state party membership routinely predates (often by years
or decades) someone's election to federal Parliament, and OpenAustralia's Term data has no signal
for it at all.

**The codebase's own ADRs already say this explicitly** — the fix should really just be making the
code match what's already documented as the intended design:

- ADR-0002: *"State Branch Membership and Minor Party Membership are never closed by Interpretation
  ... because OpenAustralia gives us no signal for when someone actually joined or left a state or
  minor party branch; they typically predate and outlast the person's time in Parliament."*
- ADR-0005: *"ADR-0002 leaves State Branch and Minor Party Membership permanently open-ended
  because OpenAustralia gives no signal for when someone actually joined or left a party branch —
  that remains true for the start of a membership."*

Both ADRs are written as if State Branch start dates are left unset, matching the precedent already
set for councils (`docs/adr/0006-council-membership-position-dates-deferred-to-interpretation.md`
— dates deferred entirely rather than recording a knowingly-wrong proxy date). The implementation
doesn't actually do that for state branches: it writes the federal-entry date as `start_date` on
both the Membership and, via `upsert_position`'s `position.start_date ||= start_date`, the Position
too — so it displays and is queryable as a real join date, not an absent one.

**Confirmed live:** Julie-Ann Campbell (`join-the-dots.info/people/447589`) shows `ALP (QLD)` —
`Party Member (QLD) | (Since 03/05/2025)`, identical to her `Australian Federal Parliament` —
`MP | (Since 03/05/2025)` and `ALP (Federal)` start dates. All three being the same date is the
tell: it's her election date, not evidence of when she joined ALP (QLD), which was almost certainly
years earlier.

## Fix direction

Stop passing `start_date` through to the State Branch/Minor Party Membership and Position at all —
mirror ADR-0006's council precedent (undated Membership, no proxy date). Touches
`record_state_branch`, `record_minor_party`, and `upsert_position`'s `start_date` handling in
`RecordMembershipsAndPositions`.

**This isn't just a code fix.** The pipeline has already run in production, so every federal
politician currently ingested via OpenAustralia has this wrong date sitting on their State Branch
Membership/Position today. Same shape of problem as
[#315](https://github.com/johnofsydney/lester/issues/315) (redundant trading names, a similarly
already-shipped bug) — a code fix alone doesn't touch existing data, and backfilling/correcting
years of already-recorded start dates across every sitting and former federal politician is its own
piece of work, needing its own review before running against production.

## Why now, why not now

Found while working on QLD council ingestion, unrelated to that work. **Explicitly not part of
this cycle** — backlog only.
