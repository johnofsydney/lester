# Transfer is a derived rollup of IndividualTransaction, eventually consistent

**Status:** Accepted

## Context

`IndividualTransaction` is the record of a specifically knowable transaction of funds from one
entity to another — a single AEC-disclosed donation, or a single AusTender contract release. It
carries the real `giver`, `taker`, `amount`, `effective_date`, `transaction_type` (`donation` or
`government_contract`), evidence, and a `fine_grained_transaction_category`.

`Transfer` predates `IndividualTransaction` in this codebase and is not itself a source of primary
financial fact. It exists as a convenience: a per-giver/taker/financial-year summary row that makes
common graph queries (money moved between two nodes, aggregated by year) cheap without summing
`IndividualTransaction` rows at query time. As a domain concept it's arguably a bit flawed — the
"correct" model may be that only `IndividualTransaction` should exist — but it's baked into enough
of the codebase (queries, caching, the graph traversal layer) that removing it outright is a bigger
question than this ADR settles. This ADR records the current, intended shape of the relationship
so every session has one place to check it, rather than reverse-engineering it from
`RecordTransfer`, the two `RecordIndividualTransaction` services, and the refresh job each time.

## Decision

- **`IndividualTransaction` is authoritative.** Type (`donation` vs `government_contract`),
  category, amount, and effective date all live there. `Transfer` should be treated as read-derived
  from its `individual_transactions`, never as an independent source of truth.
- **Grouping key: `(giver, taker, financial_year)`.** One `Transfer` groups all
  `IndividualTransaction`s between the same giver and taker that fall in the same Australian
  financial year — regardless of transaction type. (Today's implementation still includes
  `transfer_type` in the grouping key — see "Open question" below.)
- **`Transfer#amount` is the sum of its `individual_transactions`, eventually consistent.**
  `Transfers::RefreshSingleTransferAmountJob` recomputes it ~5 minutes after each new
  `IndividualTransaction` is recorded (`RecordIndividualTransaction` services enqueue it). This lag,
  and the job's integer-truncated comparison before writing, are accepted as fine — there is no
  requirement for the sum to be correct synchronously or to the cent at every instant. What matters
  is that nothing *else* is treated as the source of the amount; the job is the only writer.
- **`Transfer#effective_date` is always Australian-financial-year-end (30 June).** Derived via
  `Dates::FinancialYear#last_day` at the point of `RecordTransfer.call`/`find_or_create_by!`, from
  whichever `IndividualTransaction#effective_date` triggered the `Transfer`'s creation. Because the
  financial-year-end date is itself part of the `find_or_create` key, every `IndividualTransaction`
  attached to a given `Transfer` necessarily maps to that same financial year — there's no scenario
  where the stored `effective_date` drifts from what its children imply.
- **Australian data only.** `Dates::FinancialYear` hardcodes 30 June and the AU July–June financial
  year. No other jurisdiction's calendar is handled, and none is currently in scope.

## Open question — not decided here

Whether `Transfer` should continue to be scoped per `transfer_type` (so a giver/taker/year pair
with both a donation and a government contract produces two `Transfer` rows, as happens today) or
should collapse to one `Transfer` per giver/taker/year regardless of type (with
`IndividualTransaction#transaction_type` being the only place type is recorded, and `transfer_type`
removed from `Transfer` entirely) is unresolved. Today's code does the former
(`RecordTransfer`/`find_or_create_by!` includes `transfer_type` in both services'
`Transfer.find_or_create_by!` calls). Collapsing to the latter is the direction under
consideration, but it hasn't been decided, scoped, or implemented — this ADR records the current
behaviour, not a commitment to change it.

## Implementation reference

- `Transfer` (`app/models/transfer.rb`) — `has_many :individual_transactions`.
- `IndividualTransaction` (`app/models/individual_transaction.rb`) — `belongs_to :transfer`,
  `transaction_type` enum (`donation`/`government_contract`).
- `RecordTransfer` (`app/services/record_transfer.rb`) — advisory-lock `find_or_create_by!` keyed
  on `giver, taker, effective_date, transfer_type, evidence`.
- `AuAecDonations::RecordIndividualTransaction`, `AusTender::RecordIndividualTransaction` — each
  creates the `IndividualTransaction`, resolves/creates its parent `Transfer` via `RecordTransfer`
  with `effective_date: Dates::FinancialYear.new(...).last_day`, then enqueues
  `Transfers::RefreshSingleTransferAmountJob.perform_in(5.minutes, transfer.id)`.
- `Transfers::RefreshSingleTransferAmountJob` (`app/sidekiq/transfers/refresh_single_transfer_amount_job.rb`)
  — the sole writer of `Transfer#amount`, sums `individual_transactions`, integer-truncated
  comparison before updating, also clears `value_confirmed` on change.
- `Dates::FinancialYear` (`app/services/dates/financial_year.rb`) — hardcoded AU 30 June
  financial-year-end/start.
