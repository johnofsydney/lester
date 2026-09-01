PgSearch.multisearch_options = {
  using: {
    tsearch: { dictionary: 'english', prefix: true },
    # word_similarity matches the query against the best substring of the document,
    # so one mistyped word in a multi-word name still surfaces (plain similarity() does not).
    trigram: { word_similarity: true, threshold: 0.4 }
  },
  ignoring: [:accents]
}
