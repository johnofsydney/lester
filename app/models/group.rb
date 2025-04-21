class Group < ApplicationRecord
  include TransferMethods
  include NodeMethods
  include PgSearch::Model
  multisearchable against: [:name]

  MAJOR_POLITICAL_CATEGORIES = ['Australian Labor Party', 'Liberal / National Coalition', 'The Greens']

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
  has_many :memberships, dependent: :destroy
  has_many :people, through: :memberships, source: :member, source_type: 'Person'
  has_many :groups, through: :memberships, source: :member, source_type: 'Group' # these are the groups that _belong_ to _this_ group
  # these are a bit weird, hence the transfers method below
  has_many :outgoing_transfers, class_name: 'Transfer', as: :giver
  has_many :incoming_transfers, class_name: 'Transfer', as: :taker

  validates :name, uniqueness: { case_sensitive: false }
  validates :business_number, uniqueness: { case_sensitive: false }, allow_nil: true





  accepts_nested_attributes_for :memberships, allow_destroy: true

  # scopes
  scope :major_political_categories, -> do
    where(category: true).where(name: MAJOR_POLITICAL_CATEGORIES).order(:name)
  end
  scope :other_categories, -> do
    where(category: true).where.not(name: MAJOR_POLITICAL_CATEGORIES).order(:name)
  end

  def business_number=(value)
    return if value.blank?

    super(value.gsub(/\D/, ''))
  end


  def parent_groups
    Group.joins(:memberships).where(memberships: { member: self, member_type: 'Group' }).where.not(id: self.id)
  end

  def nodes(include_looser_nodes: false)
    unless include_looser_nodes # TODO work on includes / bullet
      return people + groups
      # TODO should this be:
      # return people + affilaietd_groups
    end

    [people + affiliated_groups + other_edge_ends].compact.flatten.uniq
  end

  def affiliated_groups
    parent_groups + groups
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
  end

  def less_level
    # only called from a disused section in FileIngestor
    name.gsub(/(Federal|NSW|VIC|SA|WA|TAS|ACT|NT)/, '')
        .delete('(')
        .delete(')')
        .strip
  end

  def state
    name.match(/(NSW|VIC|QLD|SA|WA|TAS|ACT|NT)/).to_s
  end

  def self.summarise_for(group = nil)
    major_groupings = %i(coalition nationals labor green liberals)
    states = %i[federal nsw vic qld sa wa nt act tas]

    list = major_groupings.map do |major_group|
      states.map do |state|
        NAMES.send(major_group).send(state) if NAMES.send(major_group)
      end
    end

    if group.present?
      list.flatten.compact.uniq - [group.name]
    else
      list.flatten.compact.uniq
    end
  end

  def is_category? = category?

  def merge_into(replacement_group)
    Membership.where(member: self).update_all(member_id: replacement_group.id)
    Membership.where(group: self).update_all(group_id: replacement_group.id)
    Transfer.where(giver: self).update_all(giver_id: replacement_group.id)
    Transfer.where(taker: self).update_all(taker_id: replacement_group.id)

    replacement_group.update(cached_data: {})
    self.destroy
  end

  def display_name
    return "#{name} (#{business_number})" if business_number.present?

    name
  end

  def self.all_named_parties
    NAMES.to_h.keys.map do |key|
      NAMES.send(key).to_h.values
    end.flatten.uniq
  end
end
