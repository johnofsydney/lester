# Limit OpenAustralia ingestion to the last 50 years

**Status:** Accepted

Rather than backfilling every politician in OpenAustralia's full historical dataset, ingestion is scoped to the last 50 years. This keeps the first iteration smaller and avoids a long tail of edge cases in much older data (differing conventions, sparser records, and — concretely — Frederick Holder, the first-ever Speaker in 1901, whose independent Speakership would otherwise need special-case handling; see ADR 0003). The window can be widened later once Interpretation is proven on recent, better-understood data.
