# Join the Dots

An Australian political transparency tool that maps relationships between people, organisations, money flows (donations and government contracts), and political affiliations.

## Language

### Core graph

**Person**:
An individual node in the relationship graph — a politician, donor, lobbyist, etc.
_Avoid_: User, individual

**Group**:
A collective node in the relationship graph — a party, company, charity, or government body.
_Avoid_: Organisation, entity

**Membership**:
A record that a Person or Group belonged to a Group, with an optional start and end date. The same member can hold more than one Membership in the same Group over time (e.g. rejoining).
_Avoid_: Affiliation

**Position**:
A named role a member holds during a Membership (e.g. "MP", "Party Member (VIC)"), with its own optional start and end date, independent of the Membership's own dates.
_Avoid_: Title, role

**Transfer**:
A flow of money between two nodes (Person or Group) — either a donation or a government contract.
_Avoid_: Payment, transaction, donation (too narrow — a Transfer also covers government contracts)

**Tag**:
A Group subtype used to label other Groups or People by category (e.g. a political party, "Charities", "Lobbyists").
_Avoid_: Category, label

**Current Standing**:
Which Membership represents a member's relationship with a Group right now, when more than one Membership exists between the same pair (e.g. non-contiguous stints). The open Membership if one exists, else whichever has the most recent `end_date`. A display-layer concept only — storage always keeps every Membership regardless of which one is a member's Current Standing.
_Avoid_: Last Position (the screen label for this, but do not use it as the internal name — collides with the existing, narrower `Membership#last_position`, which picks the most recent Position *within one* Membership, not across several)

### OpenAustralia ingest

**Term**:
A single row returned by the OpenAustralia API for one politician — one continuous period holding one specific chamber seat, under one party, in one electorate. OpenAustralia gives each Term its own `member_id`; a politician who changes party or electorate produces multiple consecutive Terms. A Term is OpenAustralia's shape, not ours — it must be mapped and reinterpreted to fit this app's Membership/Position model.
_Avoid_: Stint — not yet a settled domain concept (how Terms collapse into a Parliament Membership is an open, deferred question; treat any such grouping as an implementation detail, not glossary language, until it's resolved)

**Raw Terms**:
The unmodified set of Terms OpenAustralia returned for a Person on their most recent fetch, stored directly on that Person alongside when it was fetched. It is the sole input for deriving that Person's Parliament and party Memberships and Positions — interpretation replays this data and never re-fetches from OpenAustralia. Each new fetch overwrites the previous Raw Terms; only the latest snapshot is kept, not a history of past fetches.
_Avoid_: Cached data — already used on Person/Group for a different concept, the rendered graph-traversal output built by `CachedMethods`. Raw Terms is unrelated upstream source data, not a rendered/derived cache.

**Ingest**:
The phase that fetches a Person's Terms from OpenAustralia and stores them as Raw Terms. Produces no Memberships or Positions itself — it only captures OpenAustralia's data as given.

**Interpretation**:
The phase that reads a Person's Raw Terms and derives or updates their Parliament and party Memberships and Positions from them. This is where judgment calls live — grouping Terms, deciding what breaks continuity, which party layer closes when. Runs entirely off stored Raw Terms; never calls OpenAustralia itself.
_Avoid_: Mapping (already used elsewhere in this app for simple one-to-one conversions — e.g. electorate → state); Translation (implies a mechanical structural conversion, understating the judgment involved)

**Major Party**:
A political party structured in this app as two separate Groups — a Federal Branch and a State Branch — because the federal and state arms of the party are organisationally distinct. Examples: Australian Labor Party, Liberal Party, The Nationals, Australian Greens, Liberal National Party.
_Avoid_: Party (doesn't distinguish from Minor Party, which has no branch split)

**Minor Party**:
A political party structured as a single Group, with no Federal Branch / State Branch split.
_Avoid_: Party (doesn't distinguish from Major Party)

**Federal Branch Membership**:
A Person's Membership in a Major Party's Federal Branch Group. Its start and end dates are knowable — they track the Person's corresponding Parliament Membership — so Interpretation sets and closes them as parliamentary terms begin and end.

**State Branch Membership**:
A Person's Membership in a Major Party's State Branch Group. Its true start and end dates are unknowable from OpenAustralia — party branch membership typically predates and outlasts time in Parliament — so Interpretation never sets an end date on it once created. Behaves the same way, for the same reason, as a Minor Party Membership.
_Avoid_: Treating it like a Federal Branch Membership — closing it when a parliamentary term ends is a recurring mistake, not a fix (see ADR 0002)

**Office Holder**:
A chamber role — Speaker, Deputy-Speaker, President, or Deputy-President — held in addition to, not instead of, ordinary party membership and electorate representation. OpenAustralia represents this by putting the office's name (e.g. `"Speaker"`) in a Term's `party` field, which means that Term's real party is not stated directly. Interpretation infers it: an Office Holder Term takes the party of the most recent preceding Term that has a real party (skipping past any other Office Holder Terms in between), and continues that Party Branch Membership through the Office Holder period rather than treating it as a gap.
_Avoid_: Presiding Officer (only accurately describes Speaker/President, not their deputies)
