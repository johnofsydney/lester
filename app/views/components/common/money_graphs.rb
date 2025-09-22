class Common::MoneyGraphs < ApplicationView
  MAX_CHARS = 25

  include ActionView::Helpers::NumberHelper

  attr_reader :entity, :giver

  def initialize(entity:, giver: false)
    # TODO: refactor out the giver boolean. It's not very clear.
    @entity = entity
    @giver = giver
  end

  def template
    render partial: 'shared/money_graphs', locals: {
      # colors: colors(transfers, giver:),
      transfers_by_year: group_by_year, # transfers_as_giver / taker # now coming from cache
      transfers_by_name: group_by_name, # top six # now coming from cache
      entity:,
      giver:
    }
  end

  def colors(query, giver: false)
    # TODO: refactor to use cached data - which is an array of hashes
    # DO NOT find from the database. The name should be added to the cached data.
    @colors ||= begin
      if giver
        query.group(:taker_id, :taker_type)
            .sum(:amount)
            .transform_keys{ |key| key[1].constantize.find(key[0]).name }
            .map{|name, v| '#' + Digest::MD5.hexdigest(name)[0..5]}
      else
        query.group(:giver_id, :giver_type)
            .sum(:amount)
            .transform_keys{ |key| key[1].constantize.find(key[0]).name }
            .map{|name, v| '#' + Digest::MD5.hexdigest(name)[0..5]}
      end
    end
  end

  def transfers
    @transfers ||= if giver
                     entity.cached.transfers_as_giver
                   else
                     entity.cached.transfers_as_taker
                   end
  end

  def group_by_year
    @group_by_year ||= begin
      transfers.group_by{|t| t['effective_date'].to_date.year }
              .transform_values{ |ts| ts.sum{|h| h['amount'].to_f} }
              .sort_by { |year, _| year }.to_h
    end
  end

  def group_by_name
    if giver
      entity.cached.top_six_as_giver
    else
      entity.cached.top_six_as_taker
    end
  end

  def name_for_bar_graph(key)
    klass = key[1].constantize # key[1] == type, giver_type or taker_type
    instance = klass.find(key[0]) # key[0] == id, giver_id or taker_id
    name = instance.name

    return name if name.length <= MAX_CHARS

    name[0..MAX_CHARS] + '...'
  end
end