module PgSearch
  module Features
    # pg_trgm's plain word_similarity() matches the query against ANY substring of the
    # document, so short unrelated words ("sudanese", "manganese") often score higher than
    # the intended match. strict_word_similarity() anchors matches to whole-word boundaries,
    # giving much more precise typo-tolerant matching for a single mistyped word.
    class StrictWordTrigram < Trigram
      def self.valid_options
        super + [:threshold]
      end

      def conditions
        Arel::Nodes::Grouping.new(similarity.gteq(options.fetch(:threshold, 0.3)))
      end

      private

      def similarity
        Arel::Nodes::NamedFunction.new(
          'strict_word_similarity',
          [normalized_query, normalized_document]
        )
      end
    end
  end
end
