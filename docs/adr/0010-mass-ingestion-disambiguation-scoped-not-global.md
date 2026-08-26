# Mass-ingestion disambiguation: scope to an existing relationship, don't rely on a bare global name match

**Status:** Accepted

Prompted by the NSW state politicians design ([docs/plans/0011](../plans/0011-ingest-nsw-state-politicians-design.md)). pastvtr (NSWEC's results site) exposes no per-candidate identifier at all — no natural key, unlike AEC/ACNC/OpenAustralia which each give `People::RecordPerson` a real `external_id` to key disambiguation off. A bare `Person.find_by(name:)` global match is especially risky at this scale: ~93 electorates per state election, run repeatedly across cycles, against a `Person` table that already has federal politicians and general public figures in it by name — common names are near-certain to collide.

The NSW **local council** ingestion (`Councils::RecordCandidatePerson`, shipped earlier — see [docs/plans/0002](../plans/0002-local-council-councillor-ingestion.md)) already solved this exact problem for a sibling data source on the same host. Its answer: don't fall back to a global name match at all. Only reuse an existing Person if they already have a **Membership scoped to the specific thing being ingested into** (there: the specific council; here: NSW Parliament) — otherwise always create a new Person, even on a name collision with someone else globally.

**Decided:** NSW state politicians ingestion follows the same pattern — reuse an existing Person only if they already have a Membership in the NSW Parliament Group (the returning-member case), never a bare global name lookup. New service, following `Councils::RecordCandidatePerson`'s shape.

**Why:** the failure modes are asymmetric. A missed match creates a duplicate Person — visible, and mergeable later via existing admin tooling (`Admin::People::ExplodePerson`'s inverse operation). A false match silently conflates two different real people under one record — much harder to detect, and actively damaging to a transparency tool whose whole value is trustworthy provenance (see [[project_mission_and_audience]]). Scoping the reuse check to "already a member of this specific Group" trades some false splits (safe, correctable) for eliminating the much more dangerous false-merge risk a global match carries.

**General rule for future mass-ingestion sources without a third-party identifier:** don't default to a bare global name match. Scope candidate-person reuse to an existing relationship relevant to that source (a Membership in the specific Group/context being ingested into) — this is now a repeated pattern (council elections, state elections), not a one-off.
