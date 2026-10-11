class SearchResults < ApplicationView
  def initialize(results: nil)
    @results = results
  end

  attr_reader :results

  def view_template
    return if results.empty?

    div do
      results.each do |result|
        hr

        href = "/#{result.searchable_type.downcase.pluralize}/#{result.searchable_id}"
        link_text = Nodes::NameCapitalizer.capitalize(result.content)

        a(href:) { plain link_text }

        suffix = owner_name_suffix(result)
        plain " (#{suffix})" if suffix
      end
    end
  end

  private

  def owner_name_suffix(result)
    return unless result.searchable_type == 'TradingName'

    owner = trading_names_by_id[result.searchable_id]&.owner
    Nodes::NameCapitalizer.capitalize(owner.name) if owner
  end

  def trading_names_by_id
    @trading_names_by_id ||= TradingName
                             .where(id: results.select { |r| r.searchable_type == 'TradingName' }.map(&:searchable_id))
                             .includes(:owner)
                             .index_by(&:id)
  end
end

# id: 32,
# content: "John Kirby",
# searchable_type: "Person",
# searchable_id: 32,
# created_at: Thu, 22 Feb 2024 10:39:14.518121000 UTC +00:00,
# updated_at: Thu, 22 Feb 2024 10:39:14.518121000 UTC +00:00>,
