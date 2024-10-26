class Common::MoneyGraphs < ApplicationView
  MAX_CHARS = 25

  include ActionView::Helpers::NumberHelper

  attr_reader :entity, :giver

  def initialize(entity:, giver: false)
		@entity = entity
    @giver = giver
	end

  def template
    render partial: "shared/money_graphs", locals: {
      colors: colors(transfers, giver:),
      transfers_by_year: group_by_year(transfers),
      transfers_by_name: group_by_name(transfers, giver:),
      entity:, giver:
    }
  end

  def colors(query, giver: false)
    if giver
      query.group(:taker_id, :taker_type)
           .sum(:amount)
           .transform_keys{ |key| key[1].constantize.find(key[0]).name }
           .map{|name, v| "#" + Digest::MD5.hexdigest(name)[0..5]}
    else
      query.group(:giver_id, :giver_type)
           .sum(:amount)
           .transform_keys{ |key| key[1].constantize.find(key[0]).name }
           .map{|name, v| "#" + Digest::MD5.hexdigest(name)[0..5]}
    end
  end

  def transfers
    @transfers ||= if giver && entity.is_category?
                     entity.category_outgoing_transfers
                   elsif giver
                     entity.outgoing_transfers
                   elsif entity.is_category?
                     entity.category_incoming_transfers
                   else
                     entity.incoming_transfers
                   end
  end

  def group_by_year(query)
    query.group(:effective_date)
         .sum(:amount)
         .sort_by{|k, _v| k }
         .to_h
         .transform_keys{ |key| key.year }
  end

  def group_by_name(query, giver: false)
    if giver
      all_the_groups = query.group(:taker_id, :taker_type)
                          .sum(:amount)
                          .transform_keys{ |key| name_for_bar_graph(key) }
                          .sort_by{|k, v| v}
    else
      all_the_groups = query.group(:giver_id, :giver_type)
                          .sum(:amount)
                          .transform_keys{ |key| name_for_bar_graph(key) }
                          .sort_by{|k, v| v}
    end


    last_five = all_the_groups.last(5)
    sum_others = (all_the_groups - last_five).map{|a| a.last}.sum

    if sum_others.zero?
      last_five.to_h
    else
      last_five.to_h.merge('Others' => sum_others).sort_by { |_k, value| value }
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