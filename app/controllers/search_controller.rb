class SearchController < ApplicationController
  def index
    search_term = params[:query]
    @results = PgSearch.multisearch(search_term)

    transfers_recent = Transfer.order(id: :desc).last(5).sample(2)
    transfers_large = Transfer.order(amount: :desc).last(5).sample(2)

    sample_size = Group.other_categories.count

    @records = OpenStruct.new(
      people: Person.where(id: (0..Person.last.id).to_a.sample(sample_size)),
      groups: Group.where(id: (0..Group.last.id).to_a.sample(sample_size)),
      transfers: transfers_recent + transfers_large,
    )
  end
end
