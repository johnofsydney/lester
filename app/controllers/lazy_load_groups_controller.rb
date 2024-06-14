class LazyLoadGroupsController < ApplicationController
  def show
    @group = Group.find(params[:id])

    # call the methods to save the instance variables
    @giver_colors = colors(transfers_as_giver, giver: true)
    @transfers_as_giver_by_year = group_by_year(transfers_as_giver)
    @transfers_as_giver_by_name = group_by_name(transfers_as_giver, giver: true)
    @taker_colors = colors(transfers_as_taker)
    @transfers_as_taker_by_year = group_by_year(transfers_as_taker)
    @transfers_as_taker_by_name = group_by_name(transfers_as_taker)
  end

  def transfers_as_giver
    @transfers_as_giver ||= Transfer.where(giver_type: @group.class.name, giver_id: @group.id)
  end

  def transfers_as_taker
    @transfers_as_taker ||= Transfer.where(taker_type: @group.class.name, taker_id: @group.id)
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
                          .transform_keys{ |key| key[1].constantize.find(key[0]).name }
                          .sort_by{|k, v| v}
    else
      all_the_groups = query.group(:giver_id, :giver_type)
                          .sum(:amount)
                          .transform_keys{ |key| key[1].constantize.find(key[0]).name }
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
end