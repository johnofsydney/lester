# tsearch handles whole/prefix word matches; trigram catches typos (e.g. "Kevn Rudd").
# ignoring: :accents (needs the `unaccent` extension) makes both strategies accent-insensitive.
PgSearch.multisearch_options = {
  using: {
    tsearch: { dictionary: 'english', prefix: true },
    trigram: { threshold: 0.3 }
  },
  ignoring: :accents
}
