# Sole-trader ABNs have no Person path

## Where this came from

Flagged during the September 2026 trading-names uplift (PR #351, branch
`clean-up-trading-names`), which fixed matching bugs, added the `trading_names.source`
provenance column, and made `/tradingnames/:id` redirect to the owner's canonical page.
This piece was deliberately not built then because there was no column or ingest path
for it to hang off — shipping `Abn::PersonNameUpdater` would have been dead code.

## The problem

`Abn::FetchBusinessNames` (`app/services/abn/fetch_business_names.rb`) already
distinguishes sole traders in the ABR response: `sole_trader?` checks
`entityType.entityDescription`, and for sole traders `main_name` is built from
`legalName` (givenName / otherGivenName / familyName) with a `(Sole Trader)` suffix,
with `otherTradingName` + `businessName` as the trading names.

But the only consumer is `Abn::GroupNameUpdater` (via `Abn::UpdateGroupNamesJob`,
enqueued from `Groups::Record::RecordGroupWithBusinessNumber`). So **every sole-trader
ABN in the data becomes a `Group`** — a person running a business under their own ABN
is modelled as an organisation, with their legal name (plus "(Sole Trader)") as the
group name.

Person cannot yet participate because:

- `business_number` exists only on `groups` (unique-indexed,
  `index_groups_on_business_number`); `people` has no such column.
- No ingest pipeline records an ABN against a Person.
- `ExternalIdentifier::SOURCES` is `%w[aec acnc open_australia]` — no `abn` source.

## What doing this properly would need

1. **A home for the ABN on Person.** Two options:
   - A `business_number` column mirroring Group's. Simple, but perpetuates the
     column-per-identifier pattern the `external_identifiers` table was built to
     replace (see `docs/plans/0006-person-disambiguation-design.md`).
   - **Preferred:** add `abn` to `ExternalIdentifier::SOURCES` and store it via
     `ExternalIdentifiable`. Note Group's `business_number` would ideally migrate the
     same way eventually — `Nodes::Merge` already carries a
     `TODO: Should be using an external ID` next to `handle_business_number`.
2. **`Abn::PersonNameUpdater`** mirroring `Abn::GroupNameUpdater`
   (`app/services/abn/group_name_updater.rb`): fetch via `FetchBusinessNames`, update
   the canonical name, replace only `source: 'abn'` trading names (the provenance
   semantics from PR #351 — never touch `ingest`/`manual` rows), skip names identical
   to the person's own, rescue `AbnDetailsSuppressed` / `AbnNotFound` without retry.
   Spec model: `spec/services/abn/group_name_updater_spec.rb`.
3. **A routing decision at ingest time:** when an ABN lookup says "sole trader",
   should the record become a Person instead of a Group? That decision belongs
   wherever the ABN is first seen (currently `RecordGroupWithBusinessNumber`), and it
   changes the entity type mid-ingest — needs care with callers that expect a Group
   back.
4. **Existing data:** sole-trader ABNs already ingested as Groups. Decide whether to
   reclassify (hard: memberships/transfers point at the Group) or leave them and only
   route *new* sole-trader ABNs to Person. Leaving them is the safe default; a
   maintenance task to list them (`Group.where("name ILIKE '%(Sole Trader)%'")` is a
   crude first census) would size the problem before committing.

## Why it matters

For a transparency tool, a sole trader making political donations is a *person*, and
their donations should aggregate with anything else they do as a person. Modelling
them as a Group fragments the graph.
