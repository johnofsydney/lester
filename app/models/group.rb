class Group < ApplicationRecord
  include TransferMethods
  include NodeMethods
  include CachedMethods

  include PgSearch::Model
  multisearchable against: [:name]

  lazy_columns :cached_data

  MAJOR_POLITICAL_GROUPS = ['Australian Labor Party', 'Liberal / National Coalition', 'The Greens'].freeze

  NAMES = OpenStruct.new(
            coalition: OpenStruct.new(
              federal: 'the coalition (federal)',
              nsw: 'the coalition (nsw)',
              sa: 'the coalition (sa)',
              vic: 'the coalition (vic)',
              tas: 'the coalition (tas)',
              wa: 'the coalition (wa)',
              act: 'the coalition (act)'
            ),
            liberals: OpenStruct.new(
              federal: 'liberals (federal)',
              nsw: 'liberals (nsw)',
              qld: 'liberal national party (qld)',
              sa: 'liberals (sa)',
              vic: 'liberals (vic)',
              tas: 'liberals (tas)',
              wa: 'liberals (wa)',
              act: 'liberals (act)',
              nt: 'country liberal party (nt)'
            ),
            nationals: OpenStruct.new(
              federal: 'nationals (federal)',
              nsw: 'nationals (nsw)',
              qld: 'liberal national party (qld)',
              sa: 'nationals (sa)',
              vic: 'nationals (vic)',
              tas: 'nationals (tas)',
              wa: 'nationals (wa)',
              act: 'nationals (act)',
              nt: 'country liberal party (nt)'
            ),
            labor: OpenStruct.new(
              federal: 'alp (federal)',
              nsw: 'alp (nsw)',
              qld: 'alp (qld)',
              sa: 'alp (sa)',
              vic: 'alp (vic)',
              tas: 'alp (tas)',
              wa: 'alp (wa)',
              act: 'alp (act)',
              nt: 'alp (nt)'
            ),
            greens: OpenStruct.new(
              federal: 'the greens (federal)',
              nsw: 'the greens (nsw)',
              qld: 'the greens (qld)',
              sa: 'the greens (sa)',
              vic: 'the greens (vic)',
              tas: 'the greens (tas)',
              wa: 'the greens (wa)',
              act: 'the greens (act)',
              nt: 'the greens (nt)'
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

  validates :business_number, uniqueness: { case_sensitive: false }, allow_nil: true

  accepts_nested_attributes_for :memberships, allow_destroy: true

  normalizes :business_number, with: ->(bn) { bn.presence }
  normalizes :business_number, with: ->(bn) { bn.presence&.gsub(/\D/, '') }
  normalizes :name, with: ->(name) { name.downcase.strip.delete('.') }

  # scopes
  scope :major_political_tags, -> do
    where(type: 'Tag').where(name: MAJOR_POLITICAL_GROUPS).order(:name)
  end
  scope :other_tags, -> do
    where(type: 'Tag').where.not(name: MAJOR_POLITICAL_GROUPS).order(:name)
  end

  scope :political_parties, -> do
    where(
      id: Membership.joins(:group)
                    .where(groups: { type: 'Tag', name: MAJOR_POLITICAL_GROUPS })
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

  # Scope: groups that are members of the lobbyists tag
  scope :lobbyist_groups, -> {
    lobbyist_tag = Group.lobbyists_tag
    joins("INNER JOIN memberships ON memberships.member_id = groups.id AND memberships.member_type = 'Group'")
      .where('memberships.group_id = ?', lobbyist_tag.id)
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

  def is_tag?
    type == 'Tag'
  end

  def is_group? = true
  def is_person? = false

  def display_name
    return "#{name} (#{business_number})" if business_number.present?

    name
  end

  def add_to_tag(tag_group: nil, tag_name: nil)
    raise ArgumentError, 'Either tag_group or tag_name must be provided' if tag_group.blank? && tag_name.blank?
    return if self.is_tag?

    tag_group ||= Group.find_or_create_by!(name: tag_name, type: 'Tag')
    Tag::AddGroupToTag.call(tag: tag_group, group: self)
  end

  def self.all_named_parties
    NAMES.to_h.keys.map do |key|
      NAMES.send(key).to_h.values
    end.flatten.uniq
  end

  def self.find_by_name_i(name)
    Group.where('LOWER(name) = ?', name.downcase).first
  end

  def self.lobbyists_tag
    Group.find_by(name: 'Lobbyists')
  end

  def self.client_of_lobbyists_tag
    Group.find_by(name: 'Client of Lobbyists')
  end

  def self.government_department_tag
    Group.find_by(name: 'Government Departments (AU, Federal & State)')
  end
end
