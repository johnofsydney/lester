# Sole-trader ABNs have no Person path

`Abn::FetchBusinessNames` already distinguishes sole traders (legal name plus a
"(Sole Trader)" suffix as `main_name`) but the only consumer is `Abn::GroupNameUpdater`,
so every sole-trader ABN in the data becomes a `Group` today.

Person cannot yet participate: `business_number` exists only on `groups`
(unique-indexed), and no ingest path records an ABN against a Person.

## What doing this properly would need

- A way to store an ABN on a Person — either a `business_number` column mirroring
  Group's, or (better fit for existing conventions) an `external_identifiers` source
  (`abn`) via `ExternalIdentifiable`.
- An `Abn::PersonNameUpdater` mirroring `Abn::GroupNameUpdater` (same `source: 'abn'`
  trading-name semantics introduced in the trading-names uplift work).
- A decision about existing data: sole-trader ABNs already ingested as Groups — reclassify,
  or leave and only route new ones to Person.

Flagged during the 2026-09 trading-names uplift; deliberately not built then because there
was no column or ingest path for it to hang off.
