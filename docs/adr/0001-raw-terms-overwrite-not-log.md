# Raw Terms are overwritten on each fetch, not kept as an append-only log

**Status:** Accepted

When we fetch a Person's Terms from OpenAustralia, we store the raw response directly on that Person (their Raw Terms) alongside a fetched-at timestamp, and a separate interpretation step derives Memberships and Positions from it. We considered keeping an append-only history of every fetch for auditability, but decided against it: interpretation only ever needs the latest snapshot, and OpenAustralia's own data is treated as authoritative for "current known state," not as a change log we need to reconstruct. Each new fetch simply overwrites the previous Raw Terms.
