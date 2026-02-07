class Group < ApplicationRecord
  include TransferMethods
  include NodeMethods
  include CachedMethods

  include PgSearch::Model
  multisearchable against: [:name]

  lazy_columns :cached_data

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

  has_many :trading_names, as: :owner, dependent: :destroy
  has_many :leadership_websites, dependent: :destroy
  # TODO: memberships are only working on one direction, need to fix this
  # affiliated groups are not being followed from child to parent to other child
  has_many :memberships, dependent: :destroy
  has_many :people, through: :memberships, source: :member, source_type: 'Person'
  has_many :groups, through: :memberships, source: :member, source_type: 'Group' # these are the groups that _belong_ to _this_ group
  # these are a bit weird, hence the transfers method below
  has_many :outgoing_transfers, class_name: 'Transfer', as: :giver, dependent: :destroy
  has_many :incoming_transfers, class_name: 'Transfer', as: :taker, dependent: :destroy

  validates :name, uniqueness: { case_sensitive: false }
  validates :business_number, uniqueness: { case_sensitive: false }, allow_nil: true

  accepts_nested_attributes_for :memberships, allow_destroy: true

  before_validation :strip_business_number
  before_validation :nullify_empty_string_business_number

  # scopes
  scope :major_political_categories, -> do
    where(category: true).where(name: MAJOR_POLITICAL_CATEGORIES).order(:name)
  end
  scope :other_categories, -> do
    where(category: true).where.not(name: MAJOR_POLITICAL_CATEGORIES).order(:name)
  end

  scope :political_parties, -> do
    where(
      id: Membership.joins(:group)
                    .where(groups: { category: true, name: MAJOR_POLITICAL_CATEGORIES })
                    .select(:member_id)
    )
  end

  scope :with_business_number, -> { where.not(business_number: [nil, '']) }

  scope :can_refresh, -> { where(last_refreshed: nil).or(where(last_refreshed: ..6.months.ago)) }

  scope :nodes_count_expired, -> { where(nodes_count_cached_at: ..8.days.ago).or(where(nodes_count_cached: nil)) }
  scope :nodes_count_soon_expired, -> { where(nodes_count_cached_at: ..4.days.ago).or(where(nodes_count_cached: nil)) }

  scope :orphans, -> {
    # Groups with no members and no transfers. They may be children of parent groups
    left_outer_joins(:memberships, :incoming_transfers, :outgoing_transfers)
      .where(memberships: { id: nil })
      .where(incoming_transfers: { id: nil })
      .where(outgoing_transfers: { id: nil })
      .distinct
  }

  # Scope: has at least one person
  scope :with_people, -> {
    joins(:people).distinct
  }
  # Scope: has at least one group (as member)
  scope :with_groups, -> {
    joins(:groups).distinct
  }

  scope :created_since, ->(since) {
    where(created_at: since..Time.current)
  }

  # Scope: groups that are members of the lobbyists category
  scope :lobbyist_groups, -> {
    lobbyist_category = Group.lobbyists_category
    joins("INNER JOIN memberships ON memberships.member_id = groups.id AND memberships.member_type = 'Group'")
      .where('memberships.group_id = ?', lobbyist_category.id)
      .distinct
  }

  def parent_groups
    Group.joins(:memberships).where(memberships: { member: self, member_type: 'Group' }).where.not(id: self.id)
  end

  def nodes
    people + affiliated_groups
  end

  def affiliated_groups
    parent_groups + groups
  end

  def less_level
    # only called from a disused section in FileIngestor
    # TODO: Potentially useless code
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
  def is_group? = true
  def is_person? = false

  def display_name
    return "#{name} (#{business_number})" if business_number.present?

    name
  end

  def self.all_named_parties
    NAMES.to_h.keys.map do |key|
      NAMES.send(key).to_h.values
    end.flatten.uniq
  end

  def self.find_by_name_i(name)
    Group.where('LOWER(name) = ?', name.downcase).first
  end

  def self.lobbyists_category
    Group.find(1292)
  end

  def self.client_of_lobbyists_category
    Group.find(1643)
  end

  private

  def strip_business_number
    return if business_number.nil?

    self.business_number = business_number.gsub(/\D/, '')
  end

  def nullify_empty_string_business_number
    self.business_number = nil if business_number.blank?
  end
end
