# Unsuccessful candidates aren't ingested for council elections (or federal)

Every council pipeline (NSW/VIC/QLD) only ever records *declared/elected* candidates. This was
never a considered decision to exclude losing candidates — it's just never been scoped in, and the
data to do it is already sitting right there:

- QLD's `Councils::Qld::DeclaredResultsParser` fetches `<stub>-electorates.json` for every election
  it processes, and that file's `candidatesMayor`/`candidatesCouncillor` arrays already carry the
  full nomination list — winners and losers alike, with declared party where shown — but the parser
  only reads it for `electorateName` (council-name resolution) and otherwise ignores the candidate
  arrays entirely.
- NSW/VIC's results pages are similarly winner-only by choice of what the existing parsers extract,
  not a source limitation.

**We already have the mirror-able mechanism for this** — it just lives in a different pipeline.
`docs/plans/0011-ingest-nsw-state-politicians-design.md` (NSW LA/LC) designed and shipped exactly
this problem for state elections: an unsuccessful candidate is ingested *only if*
`Councils::PartyMapper` resolves their declared party to an **already-existing** `Group`. This
naturally excludes independents (no party to resolve) and micro-parties (no matching
`Group::NAMES` family, or a family match with no existing Group row) without maintaining a
separate whitelist anywhere, and keeps a losing candidate from ever picking up a Membership/
Position they didn't earn (see that doc's "Correction" section — an early draft of the NSW work
got this wrong and gave an unsuccessful candidate a sitting-member Membership).

## What this ticket is

Generalise that party-gated pattern into one rule usable across all three levels this app touches,
rather than reinventing it a third and fourth time:

- **Council** (NSW/VIC/QLD) — apply it in each `Import*ResultsJob`/`RecordContestResultJob`
  equivalent, sourced from data already being fetched (QLD's `electorates.json`; NSW/VIC would need
  their existing page-parsers extended to also capture the non-elected rows).
- **State** (NSW LA/LC) — already built; becomes the reference implementation the rule generalises
  *from*, not a new build.
- **Federal** — not yet possible with the current source. `OpenAustralia::ApiClient` only exposes
  people who've actually sat in Parliament (current or historical members), not full candidate
  lists including everyone who stood and lost. Getting federal unsuccessful candidates means a
  genuinely new source — most likely AEC's own election results (distinct from
  `AuAecDonations`, which is donations-only and unrelated). Worth checking whether this means
  **pivoting away from OpenAustralia for federal candidate/member ingestion entirely** in favour of
  AEC as a single source of truth for both winners and losers, rather than running OpenAustralia
  (members) and a new AEC pipeline (candidates) side by side — needs its own research spike before
  design, similar to how QLD's source shape had to be discovered before `0011` could be written.

## Why now, why not now

Surfaced while building QLD council ingestion (`docs/plans/0011-qld-council-councillor-ingestion.md`)
— the data was right there in `electorates.json` and it was obvious we're leaving it on the table.
**Explicitly not part of that work.** This is a new cross-cutting design question (one rule, three
election levels, a possible federal source pivot) that deserves its own scoping pass, not a
tacked-on addition to an already-shipped PR.
