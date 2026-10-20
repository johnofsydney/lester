# Exported S3 JSON is the raw internal cache shape, not consumer-shaped

**Files:** `app/sidekiq/cache/refresh_cached_data_job.rb`, `app/models/concerns/node_methods.rb`
(`to_h`)

**Context:** the per-record export (`person/<name>_<id>.json`, `group/<name>_<id>.json` in the
`join-the-dots-exports` bucket, via `Cache::RefreshCachedDataJob` → `Exports::UploadKeyContentsJob`)
is currently just `record.to_h` serialized as-is — the same internal shape `RehydratedNode` uses
to render pages (`money_in`/`money_out`, `top_six_as_giver`/`top_six_as_taker`,
`direct_connections` with `klass`/`id`/`name` keys, etc.).

The stated purpose of this export is to be an "LLM-ready" data product — but raw nested JSON with
internal field names is machine-shaped for *this app's* rendering needs, not written for a
consumer (human or LLM) with no other context. A `direct_connections` array of
`{klass, id, name}` hashes requires the reader to already know what this app's data model means;
it doesn't read as a fact on its own.

**Fix:** not yet investigated. Map the cached values into readable prose at export time (e.g. "Jane
Donor gave $500 to Acme Foundation in 2024") rather than shipping the raw hash — likely a
transform step inserted between `record.to_h` and whatever `Cache::RefreshCachedDataJob` hands to
`Exports::UploadKeyContentsJob`, so the internal cache shape (still needed for page rendering) and
the external export shape can diverge without duplicating the underlying data-gathering.
