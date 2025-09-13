class Common::MoneyGraphs < ApplicationView
  MAX_CHARS = 25

  include ActionView::Helpers::NumberHelper

  attr_reader :entity, :giver

  def initialize(entity:, giver: false)
		@entity = entity
    @giver = giver
	end

  def template
    render partial: 'shared/money_graphs', locals: {
      colors: colors(transfers, giver:),
      transfers_by_year: group_by_year,
      transfers_by_name: group_by_name(giver:),
      entity:, giver:, top_six:, others:
    }
  end

  def colors(query, giver: false)
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

  def group_by_year
    @group_by_year ||= begin
    transfers
      .to_a
      .group_by { |t| t.effective_date.year }
      .transform_values { |ts| ts.sum(&:amount) }
      .sort_by { |year, _| year }
      .to_h
    end
  end

  def all_the_groups
    # sorts the giver or takers by the amount of money they have given or taken (sum)
    # does not consider year
    @all_the_groups ||= begin
      if giver
        all_the_groups = transfers.group(:taker_id, :taker_type)
                            .sum(:amount)
                            .transform_keys{ |key| name_for_bar_graph(key) }
                            .sort_by{|k, v| v}
      else
        all_the_groups = transfers.group(:giver_id, :giver_type)
                            .sum(:amount)
                            .transform_keys{ |key| name_for_bar_graph(key) }
                            .sort_by{|k, v| v}
      end
    end
  end

  def top_five
    all_the_groups.last(5)
  end

  def others
    all_the_groups - top_five
  end

  def top_six
    sum_others = others.sum{|a| a.last}

    if sum_others.zero?
      top_five.to_h
    else
      top_five.to_h.merge('Others' => sum_others).sort_by { |_k, value| value }
    end
  end

  def group_by_name(giver: false)
    sum_others = others.sum{|a| a.last}

    if sum_others.zero?
      top_five.to_h
    else
      top_five.to_h.merge('Others' => sum_others).sort_by { |_k, value| value }
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