class Group < ApplicationRecord
  include TransferMethods
  include PgSearch::Model
  multisearchable against: [:name]


  NAMES = OpenStruct.new(
            coalition: OpenStruct.new(
              federal: 'The Coalition (Federal)',
              nsw: 'The Coalition (NSW)',
              sa: 'The Coalition (SA)',
              vic: 'The Coalition (VIC)',
              tas: 'The Coalition (TAS)',
              wa: 'The Coalition (WA)',
              act: 'The Coalition (ACT)',
            ),
            liberals: OpenStruct.new(
              federal: 'Liberals (Federal)',
              nsw: 'Liberals (NSW)',
              qld: 'Liberal National Party (QLD)',
              sa: 'Liberals (SA)',
              vic: 'Liberals (VIC)',
              tas: 'Liberals (TAS)',
              wa: 'Liberals (WA)',
              act: 'Liberals (ACT)',
              nt: 'Country Liberal Party (NT)',
            ),
            nationals: OpenStruct.new(
              federal: 'Nationals (Federal)',
              nsw: 'Nationals (NSW)',
              qld: 'Liberal National Party (QLD)',
              sa: 'Nationals (SA)',
              vic: 'Nationals (VIC)',
              tas: 'Nationals (TAS)',
              wa: 'Nationals (WA)',
              act: 'Nationals (ACT)',
              nt: 'Country Liberal Party (NT)',
            ),
            labor: OpenStruct.new(
              federal: 'ALP (Federal)',
              nsw: 'ALP (NSW)',
              qld: 'ALP (QLD)',
              sa: 'ALP (SA)',
              vic: 'ALP (VIC)',
              tas: 'ALP (TAS)',
              wa: 'ALP (WA)',
              act: 'ALP (ACT)',
              nt: 'ALP (NT)',
            ),
            greens: OpenStruct.new(
              federal: 'The Greens (Federal)',
              nsw: 'The Greens (NSW)',
              qld: 'The Greens (QLD)',
              sa: 'The Greens (SA)',
              vic: 'The Greens (VIC)',
              tas: 'The Greens (TAS)',
              wa: 'The Greens (WA)',
              act: 'The Greens (ACT)',
              nt: 'The Greens (NT)',
            )
          )



  # TODO: memberships are only working on one direction, need to fix this
  # affiliated groups are not being followed from child to parent to other child
  has_many :memberships
  has_many :people, through: :memberships, source: :member, source_type: 'Person'
  has_many :groups, through: :memberships, source: :member, source_type: 'Group' # these are the groups that _belong_ to _this_ group


  # these are a bit weird, hence the transfers method below
  has_many :outgoing_transfers, class_name: 'Transfer', foreign_key: 'giver_id', as: :giver
  has_many :incoming_transfers, class_name: 'Transfer', foreign_key: 'taker_id'

  accepts_nested_attributes_for :memberships, allow_destroy: true

  def nodes(include_looser_nodes: false)
    unless include_looser_nodes # TODO work on includes / bullet
      return people + groups
      # TODO should this be:
      # return people + affilaietd_groups

    end

    [people + affiliated_groups + other_edge_ends].compact.flatten.uniq
  end

  def affiliated_groups
    groups_as_child_member = Group.joins(:memberships)
                            .where(memberships: { member: self, member_type: 'Group' })
                            .where.not(id: self.id)

    groups_as_child_member + groups
  end


  def transfers
    OpenStruct.new(
      incoming: Transfer.where(taker: self).order(amount: :desc),
      outgoing: Transfer.where(giver: self, giver_type: 'Group').order(amount: :desc)
    )
  end

  def other_edge_ends
    # if a connection is not so strong as to be a relationship in the application
    # we can consider it an 'other' edge, so far, these are only transfers
    # at the end of an edge, there is a node,
    # at the end of a given transfer is the taker of that transfer
    # at the end of a received transfer is the giver of that transfer

    # looser nodes is too loose for looking at a list of associated people and groups, it catches too many.
    # try it for the degrees of seperation between two groups / two people / person & group


    outgoing_transfers.map(&:taker) +
    incoming_transfers.map(&:giver)
    # outgoing_transfers.includes(:giver, :taker).map(&:taker) +
    # incoming_transfers.includes(:giver, :taker).map(&:giver)
  end

  def transfers_in_value
    incoming_transfers.sum(:amount)
  end

  def less_level
    name.gsub(/(Federal|NSW|VIC|SA|WA|TAS|ACT|NT)/, '')
        .gsub('(', '')
        .gsub(')', '')
        .strip
  end

  def state
    name.match(/(NSW|VIC|QLD|SA|WA|TAS|ACT|NT)/).to_s
  end
end
