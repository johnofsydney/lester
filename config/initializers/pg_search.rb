require 'pg_search/features/strict_word_trigram'
original_feature_classes = PgSearch::ScopeOptions::FEATURE_CLASSES
PgSearch::ScopeOptions.send(:remove_const, :FEATURE_CLASSES)
PgSearch::ScopeOptions::FEATURE_CLASSES = original_feature_classes.merge(
  strict_word_trigram: PgSearch::Features::StrictWordTrigram
).freeze

PgSearch.multisearch_options = {
  using: {
    tsearch: { dictionary: 'english', prefix: true },
    strict_word_trigram: { threshold: 0.38 }
  },
  ignoring: [:accents]
}
