# Ministerial history: best structured data source

The OpenAustralia API's `office` field on Term records is too sparse to derive ministerial
position history. Confirmed in production: Anthony Albanese has only one office entry (PM,
2022–present); Peter Dutton (Defence Minister, Home Affairs Minister, Opposition Leader) has
**zero**. An alternative or supplementary source is needed to populate Membership/Position
records for ministerial portfolios.

## Candidates investigated

### 1. Wikidata (SPARQL) — recommended primary source

Wikidata models each politician's career as `P39` ("position held") statements, each with
qualifiers `P580` (start time) and `P582` (end time), pointing at a specific position entity
(e.g. "Minister for Defence (Australia)", "Prime Minister of Australia").

Verified live by querying the SPARQL endpoint directly:

```
GET https://query.wikidata.org/sparql?query=SELECT ?positionLabel ?start ?end WHERE {
  wd:Q335697 p:P39 ?stmt . ?stmt ps:P39 ?position .
  OPTIONAL { ?stmt pq:P580 ?start } OPTIONAL { ?stmt pq:P582 ?end }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}&format=json
```

- **Albanese (Q335697)**: returned 9 rows — MP since 1996, Manager of Opposition Business
  (2006–07), Leader of the House (2007–13), Minister for Infrastructure and Transport
  (2007–13, plus a separate 2013 stint), Deputy PM (Jun–Sep 2013), Minister for Communications
  etc. (Jul–Sep 2013), Opposition Leader (2019–22), PM (2022–present). This is the full career
  the OpenAustralia `office` field was missing.
- **Dutton (Q7173778)**: returned 11 rows including Minister for Home Affairs (2017–21),
  Minister for Defence (2021–22), and Leader of the Opposition (2022–25) — all three positions
  absent from the OpenAustralia office data.
- Note: my first attempt used the wrong Wikidata Q-id for Albanese (Q7414130, which 404s) —
  confirmed via web search that the correct id is Q335697. The REST fallback
  (`https://www.wikidata.org/wiki/Special:EntityData/Q335697.json`) returns the same claims
  directly in `claims.P39[].qualifiers` if SPARQL access is undesirable for some reason.
- **Licence**: CC0 (public domain) — per
  [Wikidata:Licensing](https://www.wikidata.org/wiki/Wikidata:Licensing), "All structured data
  in the main, property and lexeme namespaces is made available under the Creative Commons CC0
  License."
- **Coverage/currency**: community-maintained, continuously updated; covers politicians back to
  Federation (data quality/completeness for pre-WWII figures not separately verified here, but
  the mechanism — P39 + qualifiers — is the standard Wikidata pattern for any officeholder, not
  something specific to recent politicians).
- **Access pattern**: one SPARQL query per person (or a single query joining on "instance of:
  human" + "position held: subclass of Australian government minister" to bulk-pull many people
  at once — not executed here but the query shape is standard Wikidata practice). Requires a
  Wikidata-QID ↔ internal-Person mapping; `ExternalIdentifiable`/`external_identifiers` already
  exists as the pattern for this (currently used for `aec`/`acnc`/`open_australia` sources).

### 2. Wikipedia — fallback / cross-check, not primary

- `List_of_Australian_ministries` uses a genuine wikitable (Ministry / PM / governing party /
  dates constituted / dates concluded) — confirmed via web search of its structure, gives
  ministry-level (not per-portfolio) date ranges.
- Individual ministry pages (e.g. `Albanese_Ministry`) are **redirects**: fetching
  `https://en.wikipedia.org/w/api.php?action=parse&page=Albanese_Ministry&format=json&prop=wikitext`
  returned only `#REDIRECT [[First Albanese ministry]]` — confirmed live. The real target,
  `First_Albanese_ministry`, does contain a structured `{| class="wikitable sortable"` per
  minister/portfolio (confirmed live via the same API against that page) — but redirects have to
  be resolved first (`&redirects=1` on the API call), and the tables mix wikitext markup,
  templates (`{{post-nominals|...}}`), and embedded images that need parsing/cleanup, unlike
  Wikidata's clean typed statements.
- **Licence**: CC BY-SA — attribution and share-alike required, stricter than Wikidata's CC0.
- **Verdict**: usable as a secondary cross-check or for filling ministry-level (not
  person-level) date ranges, but not worth building a wikitext-table parser as the primary
  ingest path when Wikidata gives the same facts pre-structured.

### 3. Australian Parliamentary Handbook (aph.gov.au)

- `handbook.aph.gov.au` is described as the authoritative source, covering 1901–present,
  including ministries and shadow ministries — found via web search, not independently fetched
  as structured data in this investigation.
- No API or downloadable dataset was found for it (only browsable HTML pages per the search
  results). Would require HTML scraping, with no indication of a stable machine-readable
  export. Not recommended without a follow-up check for a hidden API/export endpoint — treat
  as unconfirmed, lowest priority.

### 4. data.gov.au

- No ministry/ministerial-history dataset found via search. Turned up only the "Australian
  Government Organisations Register" (organisations, not ministers) and PM&C speech/media
  transcripts — neither relevant. Ruled out.

### 5. They Vote For You (theyvoteforyou.org.au) / OpenAustralia Foundation projects

- Public API (`GET /api/v1/people.json?key=...`) covers only *current* members — name,
  electorate, party — no ministerial history. `help/data` page returned HTTP 403 on direct
  fetch (likely bot-blocked); web search summary didn't surface a bulk data dump covering
  ministerial positions specifically. The GitHub repo (`openaustralia/theyvoteforyou`) parses
  Hansard/ParlParse debate XML for voting data, not officeholder history. Ruled out as a
  ministerial-history source (it solves a different problem — voting records).

## Recommendation

**Wikidata SPARQL as the primary structured source**, with the List of Australian ministries
Wikipedia table available as a secondary cross-check for ministry-level date ranges. Reasons:

- It's the only candidate with confirmed, complete, per-portfolio start/end dates, verified live
  against two real gaps in the current data (Albanese pre-2022, Dutton entirely).
- CC0 licence — no attribution/share-alike obligation, simplest to depend on.
- Structurally similar enough to the existing OpenAustralia ingest to slot into the same
  Ingest/Interpretation split: an Ingest step stores raw P39 statements (position QID + start +
  end, keyed by Wikidata QID) with no interpretation, mirroring ADR-0001 ("raw terms overwrite,
  not log"); an Interpretation step turns those into Membership/Position records against the
  same Group-per-portfolio model already used for parties, deciding open questions analogous to
  ADR-0002/0003 (which Wikidata positions map to which internal Group, how a term with no P582
  end date should be treated as "current").

**Effort, relative to the existing OpenAustralia ingest/interpretation pipeline** (which spans
~6 ADRs covering term-overwrite semantics, party inheritance, branch-closing rules, and a
50-year ingestion window): comparable in shape but smaller in scope. The new pieces needed:

1. A QID ↔ Person mapping step (new `external_identifiers` source, e.g. `wikidata`) — matching
   effort is a subset of what `Entity::RecordEntityWithExternalId` already solves, since most
   federal politicians will already exist as `Person` records from the OpenAustralia ingest;
   this is enrichment, not first-time entity creation.
2. A raw-storage Ingest job per person (SPARQL or REST fetch of P39 claims) — simpler than the
   OpenAustralia Term ingest since Wikidata returns a flat list of typed statements, not the
   nested Term/office structure OpenAustralia uses.
3. An Interpretation step mapping ~30–50 distinct "Minister for X (Australia)" Wikidata position
   entities to internal Groups, plus decisions on open-ended terms (no P582) and multi-entry
   reshuffles (Albanese's Infrastructure portfolio has two separate P39 entries either side of a
   2013 gap) — this is the part that most resembles the existing Interpretation complexity, and
   where new ADRs would likely be needed (an equivalent of ADR-0002/0003 for ministerial
   positions specifically).

Rough sizing: **noticeably smaller than the original OpenAustralia ingest+interpretation build**
(no 50-year historical-conventions problem, no Hansard-scale data volume — this is one
SPARQL-shaped fact per person), but not trivial — expect it to land in the same order of
magnitude as ADR-0006's scope (single well-defined feature, a handful of edge-case decisions,
one new ADR or two) rather than a multi-PR effort like the original ingest/interpretation split.
