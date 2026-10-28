class Group < ApplicationRecord
  include TransferMethods
  include NodeMethods
  include CachedMethods
  include Attributable

  include ExternalIdentifiable

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

  scope :by_trading_name, lambda { |value|
    return all if value.blank?

    joins(:trading_names).where(trading_names: { name: TradingName.normalize_value_for(:name, value) })
  }

  def self.ransackable_scopes(_auth_object = nil)
    %i[by_external_identifier by_trading_name]
  end

  has_many :memberships, dependent: :destroy
  has_many :memberships_as_member, as: :member, class_name: 'Membership', dependent: :destroy
  has_many :people, through: :memberships, source: :member, source_type: 'Person'
  has_many :groups, through: :memberships, source: :member, source_type: 'Group' # these are the groups that _belong_ to _this_ group
  # these are a bit weird, hence the transfers method below
  has_many :outgoing_transfers, class_name: 'Transfer', as: :giver, dependent: :destroy
  has_many :incoming_transfers, class_name: 'Transfer', as: :taker, dependent: :destroy

  after_update_commit { broadcast_refresh_to(self) }

  validates :business_number, uniqueness: { case_sensitive: false }, allow_nil: true

  accepts_nested_attributes_for :memberships, allow_destroy: true

  normalizes :business_number, with: ->(bn) { bn.presence }
  normalizes :business_number, with: ->(bn) { bn.presence&.gsub(/\D/, '') }
  normalizes :name, with: ->(name) { name.downcase.strip.delete('.') }

  # scopes
  scope :major_political_tags, lambda {
    where(type: 'Tag').where(name: MAJOR_POLITICAL_GROUPS).order(:name)
  }
  scope :other_tags, lambda {
    where(type: 'Tag').where.not(name: MAJOR_POLITICAL_GROUPS).order(:name)
  }

  scope :political_parties, lambda {
    where(
      id: Membership.joins(:group)
                    .where(groups: { type: 'Tag', name: MAJOR_POLITICAL_GROUPS })
                    .select(:member_id)
    )
  }

  MATCHING_NAME_SIMILARITY_THRESHOLD = 0.4

  # strict_word_similarity anchors to whole-word boundaries, so a short query against a
  # long multi-word name (e.g. "labor" vs "Australian Labor Party") still matches -
  # plain similarity()/the % operator scores that too low to pass its default threshold.
  scope :matching_name, lambda { |term|
    where(sanitize_sql_array(['strict_word_similarity(?, name) >= ?', term, MATCHING_NAME_SIMILARITY_THRESHOLD]))
      .order(Arel.sql(sanitize_sql_array(['strict_word_similarity(?, name) DESC', term])))
  }

  scope :with_business_number, -> { where.not(business_number: [nil, '']) }
  scope :nodes_count_expired, -> { where(nodes_count_cached_at: ..8.days.ago).or(where(nodes_count_cached: nil)) }
  scope :nodes_count_soon_expired, -> { where(nodes_count_cached_at: ..4.days.ago).or(where(nodes_count_cached: nil)) }

  scope :orphans, lambda {
    # Groups with no members and no transfers. They may be children of parent groups
    left_outer_joins(:memberships, :incoming_transfers, :outgoing_transfers)
      .where(memberships: { id: nil })
      .where(incoming_transfers: { id: nil })
      .where(outgoing_transfers: { id: nil })
      .distinct
  }

  # Scope: has at least one person
  scope :with_people, lambda {
    joins(:people).distinct
  }
  # Scope: has at least one group (as member)
  scope :with_groups, lambda {
    joins(:groups).distinct
  }

  scope :created_since, lambda { |since|
    where(created_at: since..Time.current)
  }

  # Scope: groups that are members of the lobbyists tag
  scope :lobbyist_groups, lambda {
    lobbyist_tag = Group.lobbyists_tag
    joins("INNER JOIN memberships ON memberships.member_id = groups.id AND memberships.member_type = 'Group'")
      .where('memberships.group_id = ?', lobbyist_tag.id)
      .distinct
  }

  def parent_groups
    Group.joins(:memberships).where(memberships: { member: self, member_type: 'Group' }).where.not(id: id)
  end

  def nodes
    people + affiliated_groups
  end

  def affiliated_groups
    parent_groups + groups
  end

  def state
    name.match(/(NSW|VIC|QLD|SA|WA|TAS|ACT|NT)/).to_s
  end

  def self.summarise_for(group = nil)
    major_groupings = %i[coalition nationals labor green liberals]
    states = %i[federal nsw vic qld sa wa nt act tas]

    list = major_groupings.map do |major_group|
      states.map do |state|
        NAMES.send(major_group)&.send(state)
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
    Nodes::NameCapitalizer.capitalize_for('Group', name)
  end

  # rubocop:disable Style/StringConcatenation # feels nicer in this case
  def tweet_body
    body = <<~SUMMARY.strip
      🔍 #{name}

      👥 #{nodes_count} #{'connection'.pluralize(nodes_count)} in our database.

      💰 Money Tracker:
      ➡️ In: #{money_in || 'None'}
      ⬅️ Out: #{money_out || 'None'}
    SUMMARY

    call_to_action = "\n\n" + "See more: https://join-the-dots.info/groups/#{id}"
    body += call_to_action if (body.length + call_to_action.length) < 300
    aus_pol_tag = "\n\n" + '#AusPol'
    body += aus_pol_tag if (body.length + aus_pol_tag.length) < 300
    name_to_tag = ' #' + name.downcase.tr(' ', '_')
    body += name_to_tag if (body.length + name_to_tag.length) < 300
    final_sign_off = ' #follow_the_money'
    body += final_sign_off if (body.length + final_sign_off.length) < 300

    body.strip
  end
  # rubocop:enable Style/StringConcatenation

  def add_to_tag(tag_group: nil, tag_name: nil)
    raise ArgumentError, 'Either tag_group or tag_name must be provided' if tag_group.blank? && tag_name.blank?
    return if is_tag?

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

  def self.charities_tag
    find_seeded(124_513, :charities_tag)
  end

  def self.lobbyists_tag
    find_seeded(124_509, :lobbyists_tag)
  end

  def self.client_of_lobbyists_tag
    find_seeded(124_510, :client_of_lobbyists_tag)
  end

  def self.government_department_tag
    find_seeded(124_514, :government_department_tag)
  end

  def self.federal_parliament
    find_seeded(877, :federal_parliament)
  end

  def self.nsw_parliament
    find_seeded(3740, :nsw_parliament)
  end

  def self.local_councils_tag
    find_seeded(132_067, :local_councils_tag)
  end

  # These IDs only exist because production is seeded into dev/staging with PKs preserved
  # (see db/seeds.rb). A DB without that seed data raises RecordNotFound with no indication
  # of which constant or seed step was missing.
  def self.find_seeded(id, method_name)
    Group.find(id)
  rescue ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound,
          "Group.#{method_name} expects group id #{id} to exist. This ID is seeded from " \
          'production (see db/seeds.rb and `bin/rails seed_data:extract`) and is not ' \
          'present on this database.'
  end
  private_class_method :find_seeded
end
