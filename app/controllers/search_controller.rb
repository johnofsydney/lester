class SearchController < ApplicationController
  def index
    search_term = params[:query]
    @results = PgSearch.multisearch(search_term)

    @transfers_recent = Transfer.order(id: :desc).last(5)
    @transfers_large = Transfer.order(amount: :desc).last(5)
    @people_recent = Person.order(id: :desc).last(5)
    @people_nodeish = Person.all.sort_by { |person| person.nodes.count }.reverse.last(5)
    @groups_recent = Group.order(id: :desc).last(5)
    @groups_nodeish = Group.all.sort_by { |group| group.nodes.count }.reverse.last(5)

    @random = @transfers_recent.take(2)
    
  end

  def linker
    player_one = params[:player_one]
    player_two = params[:player_two]

    p params.inspect
    return unless player_one && player_two

    player_one_class = PgSearch.multisearch(params[:player_one]).first.searchable_type
    player_one_id = PgSearch.multisearch(params[:player_one]).first.searchable_id
    node_1 = player_one_class.constantize.find(player_one_id)
    player_two_class = PgSearch.multisearch(params[:player_two]).first.searchable_type
    player_two_id = PgSearch.multisearch(params[:player_two]).first.searchable_id
    node_2 = player_two_class.constantize.find(player_two_id)

    linker_instance = NodeLinker.new(node_1, node_2)

    @shortest_path = linker_instance.summarize_links
  end
end
