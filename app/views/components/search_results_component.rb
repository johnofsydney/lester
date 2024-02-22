class SearchResultsComponent < ApplicationView
  def initialize(results: nil)
    @results = results
  end

  attr_reader :results

  def template
    return if results.empty?

    p { results.map{|r| r.content } }
    ul do
      results.each do |result|
        li { result.content }
      end
    end
  end
end