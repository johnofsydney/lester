class SearchResults < ApplicationView
  def initialize(results: nil)
    @results = results
  end

  attr_reader :results

  # rubocop:disable Style/EmptyElse
  def view_template
    return if results.empty?

    div do
      results.each do |result|
        hr

        href = "/#{result.searchable_type.downcase.pluralize}/#{result.searchable_id}"
        link_text = result.content

        suffix = if result.searchable_type == 'TradingName'
                   result.searchable_type.constantize.find(result.searchable_id).owner.name
                 else
                   nil
                 end

        a(href:) { plain link_text }

        plain " (#{suffix})" if suffix
      end
    end
  end
  # rubocop:enable Style/EmptyElse
end

# id: 32,
# content: "John Kirby",
# searchable_type: "Person",
# searchable_id: 32,
# created_at: Thu, 22 Feb 2024 10:39:14.518121000 UTC +00:00,
# updated_at: Thu, 22 Feb 2024 10:39:14.518121000 UTC +00:00>,
