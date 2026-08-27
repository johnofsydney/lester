# `Group.type == 'Tag'` is a fixed, human-curated category — agent code never creates one

**Status:** Accepted

## Context

A `Group` can carry `type: 'Tag'` (an STI subclass, `Tag < Group`). This has caused real confusion: `CLAUDE.md` states "Tags are used as political party labels and category labels," which reads as if political parties themselves are Tags — they are not, and this ADR exists partly to correct that impression at its source.

During NSW state politicians ingest ([docs/plans/0011](../plans/0011-ingest-nsw-state-politicians-design.md)), a winner's party-Group lookup was written as `Group.find_or_create_by!(name: canonical_name, type: 'Tag')`, on the assumption that a party like "ALP (NSW)" is a Tag. It silently created 4 duplicate Groups instead of finding the real, pre-existing ones — of the 36 `Group::NAMES`-derived party Groups actually in the DB, 32 are plain Groups (`type: nil`) and only 4 were the duplicates this bug had just created.

## Decision

**A Tag is a fixed category — mining, superannuation, energy, consulting, Charities, Lobbyists, Australian Local Councils, and (confusingly) the three major political-party families — created only by John, the project owner, never by Claude or agent-written ingestion code.** A Tag is an "umbrella collection of other Groups": real-world entities become *members of* a Tag to say "this Group belongs to this fixed category," they are never the Tag itself.

Concretely:
- A real charity is a plain Group; it becomes a *member* of `Group.charities_tag` to say "this Group is a charity" (`Tag::AddGroupToTag` → `Membership.find_or_create_by!(group: tag, member: group)`, Tag on the `group` side, real entity on the `member` side).
- `Group::MAJOR_POLITICAL_GROUPS` (`'Australian Labor Party'`, `'Liberal / National Coalition'`, `'The Greens'`) are Tags in the same sense — three of John's fixed categories happen to be political-party-family umbrellas. A real, specific party branch (`Group::NAMES.labor.nsw` → `'alp (nsw)'`) is a **plain Group**, and it is what a Person is directly a Member of (their actual party affiliation). The branch Group *may* also be a member of the relevant family Tag (`Group.political_parties` scope resolves this), but that's a separate, coarser rollup concept from the Person's real Membership.

**Hard rule: agent/ingestion code must never call `Group.create!` or `find_or_create_by!` with `type: 'Tag'`, or any method (like `Group#add_to_tag` when passed `tag_name:` for a name that doesn't yet exist) that could create a new Tag as a side effect.** Categories are fixed unless John changes them; code may look up an existing Tag by name/id and skip or error if it's missing, but must never invent one. This is stricter than "avoid it for parties" — it applies to every Tag, not just the political-family ones that triggered this ADR.

**Assigning an existing Group into an existing Tag is fine — both programmatically (as ingestion) and manually (as an admin action) — and both are already established, explicitly-built patterns.** The rule this ADR sets is narrower than "never assign into a tag": **it's specifically "never create a new Tag," not "never assign into one."**

- **Ingestion:** `Councils::{Nsw,Vic}::ImportCouncilResultRowJob` already adds each ingested council into `Group.local_councils_tag` as part of ingestion (`council.add_to_tag(...)`) — confirmed by John during this ADR's Q&A as the intended, wanted behaviour, not a gap. A future feature that assigns Groups into a category programmatically (John: "potentially we will have ways of programmatically assigning groups into a category") is a natural extension of this same already-accepted pattern, not a boundary this ADR is drawing a line around — it just isn't built for anything beyond local councils yet.
- **Admin (manual, human-driven):** `app/admin/groups.rb`'s `add_to_tag` batch action lets John select existing Groups and assign them into an existing Tag (`tag_id` choices come from `Group.other_tags` — already-existing Tags only, no create path) — also fine, and the expected way John himself curates category membership by hand.

Both are safe under this ADR precisely because neither can create a new Tag — the ingestion path looks up `Group.local_councils_tag` (a fixed, hardcoded lookup), and the admin path only ever offers already-existing Tags to choose from.

## A real gap this ADR did surface: `add_to_tag` can still create a Tag if given a name

The council ingestion's *assignment* behaviour is correct and wanted, but the mechanism it goes through has a sharp edge: `council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)` passes a **name**, which routes through `Group#add_to_tag`'s `tag_group ||= Group.find_or_create_by!(name: tag_name, type: 'Tag')` — the create-capable path this ADR rules out. In practice `'Australian Local Councils'` already exists (`Group.local_councils_tag`, hardcoded id 132067), so this has never actually created a Tag — but the capability is live in ingestion code today. Worth a follow-up: change these two call sites to pass `tag_group: Group.local_councils_tag` (a lookup, not a name that could miss) instead of `tag_name:` — same assignment behaviour, just via the hard-lookup path instead of the create-capable one. Not changed as part of this ADR since it's outside the NSW state politicians ticket's scope — flagged for the project owner to prioritise separately.

## Consequence

Any code resolving or creating a party Group for a Person's Membership (`Councils::PartyMapper`, `NswStatePoliticians::RecordLaCandidate`, and any future ingestion source) looks up and creates against `Group::NAMES`' plain-Group convention — `Group.find_by_name_i(canonical_name)` / `Group.create!(name: canonical_name)`, no `type:` — never `type: 'Tag'`. `MapGroupNamesAecRecipients` and `Councils::PartyMapper` already did this correctly; the NSW state politicians winner-path bug was a one-off deviation, now fixed.

Test fixtures that need to simulate a pre-existing, John-created Tag (e.g. stubbing `Group.local_councils_tag`) may still construct a `type: 'Tag'` Group directly — that's simulating what already exists in production, not agent code inventing a category. But fixtures for a *party branch* Group (the thing a Person is actually a Member of) should be plain Groups, matching the real convention — several specs across this codebase got this wrong (see the retro in [docs/plans/0011](../plans/0011-ingest-nsw-state-politicians-design.md)) and were fixed as part of this work.
