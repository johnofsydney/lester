# Ingest Federal Politicians — Design & Roadmap

## Current status (2026-07-19)

**Increment 1 — Ingest — is done and verified on staging.** See [issue #209](https://github.com/johnofsydney/lester/issues/209) (parent spec), [#210](https://github.com/johnofsydney/lester/issues/210) and [#211](https://github.com/johnofsydney/lester/issues/211) (implementation tickets).

What exists today:
- `OpenAustralia::ApiClient` — Faraday wrapper for `getRepresentative(id)`, `getSenator(id)`, `getRepresentatives`, `getSenators`.
- `OpenAustralia::IngestPerson.call(person_id:)` — fetches a person's full Term history from **both** chambers, merges chronologically, resolves/creates the `Person` via the existing `People::RecordPerson` name/external-identifier logic, and stores the raw merged Terms on `open_australia_data` (jsonb) / `open_australia_data_fetched_at` (timestamp) columns on `people`.
- `OpenAustralia::IngestCurrentPoliticians.call` — fetches the current roster (`getRepresentatives` + `getSenators`), enqueues one `IngestPersonJob` per distinct `person_id`.
- `open_australia_id` on `ExternalIdentifiable` / `People::RecordPerson`.

**Deliberately not done in Increment 1** (see `CONTEXT.md` and `docs/adr/`):
- No `Membership`/`Position` records are created — this is Ingest only, not Interpretation.
- Only *currently-serving* politicians are ingested (~226 people) — not the full 50-year historical set.
- No freshness/staleness checking, no throttling, no scheduled trigger — console-only, unconditional overwrite on each run.

Domain vocabulary (Term, Raw Terms, Ingest, Interpretation, Major/Minor Party, Federal/State Branch Membership, Office Holder, Current Standing) is defined in `CONTEXT.md`. Settled decisions are recorded in `docs/adr/0001`–`0004`. Read both before starting any of the work below — several non-obvious rules (e.g. state-branch memberships never get an `end_date`) are already resolved there, don't re-derive them.

---

## Increment 2 — Interpretation (next up)

Turn each Person's `open_australia_data` (their Raw Terms) into real `Membership`/`Position` records: one Parliament Membership per continuous stint, one Federal Branch Membership per major party (closed when the parliamentary term ends — ADR 0002), one State Branch / Minor Party Membership per party (never auto-closed — ADR 0002), with Office Holder terms (Speaker/Deputy-Speaker/President/Deputy-President) inheriting party from the preceding real-party Term (ADR 0003).

This is where essentially all the complexity from the first (abandoned) attempt lived. Known hard parts, already identified but **not yet re-solved** in this rebuild:

- **Grouping Terms into a single continuous Parliament Membership** — contiguous Terms (where one's `left_house` equals the next's `entered_house`) should collapse into one Membership; a real gap (lost seat, later re-elected) should be two. `CONTEXT.md` deliberately left this internal-method-level detail unnamed ("Stint" was explicitly rejected as a glossary term) — work out the grouping logic fresh, don't resurrect the old `group_into_stints` code wholesale, since it had a real bug (an Office Holder term could silently merge into the next contiguous term and lose its title — the `chunk_while` predicate only checked the *current* term, not the *previous* one).
- **Federal vs State Branch vs Minor Party group resolution** — mapping a `party` string to the right Group(s), including electorate→state lookup for MPs (state is direct on the Term for Senators, but MPs only give an electorate name). A `MapElectorateToState`-style lookup table existed in the abandoned branch; may be worth rebuilding, or reconsider using `getDivisions` if it exists.
- **Party string audit** — how do OpenAustralia's party strings (`"Australian Labor Party"`, `"The Nationals"`, etc.) compare against existing AEC-sourced Tags already in the DB? Needs a live comparison now that the API key works — this was blocked before, isn't now.
- **Idempotency** — Interpretation needs to be safely re-runnable (re-run after a fresh Ingest fetch) without duplicating Memberships/Positions.

Suggest running this against the ~226 already-ingested current politicians as the test bed before touching historical data at all.

---

## Increment 3 — Historical backfill (after Interpretation is proven)

Goal: ingest *all* federal politicians within the 50-year window (ADR 0004), not just current ones.

This needs its own design pass — it's a genuinely different problem from Increment 1, not just "run the same thing on a bigger list":

- There's no single "everyone who's ever served" roster endpoint. `getRepresentatives`/`getSenators` take an optional `date` param and return the roster *as it stood on that date* — historical discovery means querying across many historical dates and deduplicating `person_id`s.
- A naive approach (one query per election date) has a real gap: someone who won a by-election and then lost their seat (or died, or resigned) entirely between two general elections would never appear in any election-day snapshot. Sampling more densely (e.g. every few months) reduces but may not eliminate this risk — worth explicitly deciding what risk is acceptable rather than discovering it by omission.
- Whatever discovery strategy is chosen, it only needs to produce a list of `person_id`s — `OpenAustralia::IngestPerson` (already built) handles the rest unchanged, since it always fetches a person's *entire* Term history regardless of which date surfaced them.
- Volume is much larger than 226 — worth revisiting whether throttling is still unnecessary (Increment 1 deliberately skipped it for a one-off ~226-person run; that reasoning doesn't automatically extend to a much larger historical run).

Run `/grill-with-docs` for this increment specifically before implementing — the discovery-strategy question above needs a real decision, not an assumption.

---

## Later — Ministries and Cabinet offices

Each Term OpenAustralia returns already includes an `office` array — ministerial/shadow ministerial positions with date ranges (`{ moffice_id, dept, position, from_date, to_date, person, source }`). **This data is already being captured** — Increment 1 stores the whole raw Term unmodified in `open_australia_data`, `office` included. No new Ingest work is needed for this; it's purely a future Interpretation concern reading data that's already there.

When picked up:
- Each `office` entry → a `Membership` between the Person and a Department Group (find-or-create by `dept`), with a `Position` (`title` = `position` string, dates from `from_date`/`to_date`).
- A **Ministry** (the collective cabinet under a PM — "Albanese Ministry", "Morrison Ministry") is its own concept, not directly given by OpenAustralia — grouping office-holders into a Ministry needs PM tenure date ranges from elsewhere (not in this API). Design separately; don't conflate with the per-office Membership work above.

---

## Reference: OpenAustralia API

- Base URL: `https://www.openaustralia.org.au/api/`
- Auth: `key=VALUE` query param on every request — `Rails.application.credentials.dig(:open_australia, :api_key)` (now set).
- Output: `output=js` returns JSON.
- Docs: https://www.openaustralia.org.au/api/

### `getRepresentatives` / `getSenators` (roster, no ID)
Returns all members as of a given date (`date` param, ISO — omit for today). Also takes optional `party`/`search` filters, and `state` (senators only). Confirmed live: 150 representatives, 76 senators currently.

### `getRepresentative` / `getSenator` (singular, by `person_id`)
Returns that person's **full Term history** in that chamber — every row they've ever had, not just current. Confirmed field shape from live data:

```json
{
  "member_id": "6", "house": "1", "first_name": "Anthony", "last_name": "Albanese",
  "constituency": "Grayndler", "party": "Australian Labor Party",
  "entered_house": "1996-03-02", "left_house": "9999-12-31",
  "entered_reason": "general_election", "left_reason": "still_in_office",
  "person_id": "10007", "title": "", "lastupdate": "2008-04-26 11:08:04",
  "full_name": "Anthony Albanese", "name": "Anthony Albanese",
  "image": "/images/mpsL/10007.jpg",
  "office": [{ "moffice_id": "287830", "dept": "", "position": "Prime Minister",
                "from_date": "2022-06-01", "to_date": "9999-12-31", "person": "10007", "source": "" }]
}
```

Note: `house` is the string `"1"` (Representatives) or `"2"` (Senate) — **not** `"representatives"`/`"senate"` as originally guessed before live API access was available. `left_house` is `"9999-12-31"` (not blank) when currently serving.

`person_id` is stable across a person's entire career, even across chambers (confirmed: Barnaby Joyce is `person_id: "10350"` for both his Senate and House terms) — this is why `IngestPerson` calls both `get_representative` and `get_senator` for every person regardless of which chamber they're currently in.
