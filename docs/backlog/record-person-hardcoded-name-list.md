# RecordPerson's hardcoded name-mapping list is unbounded tech debt

## Where this is

`People::RecordPerson.clean_name` (`app/services/people/record_person.rb`). After the
legitimate normalisation steps (comma-reversed "Surname, First" ordering, stripping
titles/honours like MP / Senator / OAM / Hon. / Dr, `CapitalizeNames`), the method ends
with ~30 hardcoded early returns of the form:

```ruby
return 'David Pocock' if name.match?(/David Pocock/i)
return 'Tony Windsor' if name.match?(/Antony Harold Curties Windsor/i)
return 'Mike Cannon Brookes' if name.match?(/(Mike|Michael) Cannon.+Brookes/i)
...
```

The method's own comments admit it: "This is temporary, and should be replaced with a
name disambiguator".

## Why it exists

Different sources spell the same person differently — AEC disclosures use full legal
names ("Antony Harold Curties Windsor"), OpenAustralia uses common names ("Tony
Windsor"). Before `trading_names` and `external_identifiers` existed, mapping variants
to one canonical spelling in code was the only way to stop each source creating its own
Person. Each entry was added ad hoc when a duplicate was noticed — mostly federal
politicians and prominent donors.

## Why it's the wrong mechanism now

The infrastructure that supersedes it already exists:

- **`external_identifiers`** (see `docs/plans/0006-person-disambiguation-design.md`,
  implemented): when a source ID is present, `Entity::RecordEntityWithExternalId`
  matches on the ID and records the incoming name variant as a trading name — no
  code-level mapping needed.
- **`trading_names` fallback**: since PR #351, `People::RecordPerson#call` falls back to
  `TradingName.sole_owner_for(name, owner_type: 'Person')` — a variant recorded once
  (by ingestion or by hand in the TradingName admin, which now supports create/edit)
  resolves to the right person on every later ingest.

So each hardcoded line is equivalent to one `TradingName` row — except it's invisible
to the admin UI, can't be corrected without a deploy, only fires inside
`clean_name`, and the regexes are riskier than exact rows (e.g. `/David Pocock/i`
matches any *other* David Pocock; `/Jacinta.+Price/i` matches any Jacinta ... Price).

## Migration path (small, safe increments)

1. **Freeze the list** — no new entries; new variants get a TradingName row instead
   (via the admin UI or ingestion).
2. **Convert entries to data.** For each hardcoded pair: confirm the canonical Person
   exists, create the variant as a `TradingName` (`source: 'manual'`) on them, then
   delete the code line. The regex-y entries (`/Kylea.+Tink/`) need the concrete
   variants actually seen in the data — check existing trading names and
   `external_identifiers` on the person, and the AEC source strings, before assuming.
   A one-off script or maintenance task could seed the exact-string cases; the fuzzy
   ones want eyeballing.
3. **Verify per repo convention** — after each batch, re-run the relevant ingest
   against real data (not just specs) and confirm no new duplicate People appear:
   `Person.group(:name).having('count(*) > 1').count` plus a spot-check of the
   affected people's pages.
4. Also remove the related TODO comments at the `Person.find_by(name:)` and
   trading-name fallback branches of `#call` once the mechanism is trusted.

## Caveats

- The mapping runs on *every* incoming name from *every* source; trading-name fallback
  only fires when the exact-name match fails. Behaviour is equivalent for these cases
  (the hardcoded target *is* an existing person), but verify a couple end-to-end
  before bulk-converting.
- `clean_name` mappings are compile-time and case-insensitive-regex; trading names are
  normalised exact strings (downcase/strip/de-dot). A variant list that relied on
  regex breadth ("Jacinta *anything* Price") narrows to the specific observed strings
  — that is a feature (precision), but means watching for a missed variant creating a
  duplicate on the next ingest run, which the dedupe check in step 3 catches.
- The *general* title-stripping regexes at the top of `clean_name` are fine and stay.
