# Resolves an election candidate's name to a Person, scoped to a specific Group -- deliberately
# does NOT fall back to a bare global name match like People::RecordPerson does.
#
# Election results sites (NSWEC/VEC, for both council and state elections) expose no per-candidate
# ID at all (confirmed live -- their pages carry nothing beyond name, party, and a per-ballot
# position that resets every contest), so there's no external_identifiers-style key to
# disambiguate on. A global "Person.find_by(name:)" is especially risky here: common names are
# near-certain to collide across genuinely different people in different contests (or with an
# unrelated same-named Person from AEC/ACNC/OpenAustralia data).
#
# So candidate resolution only reuses an existing Person if they already have a Membership at THIS
# scope Group (the returning-member case) -- otherwise it always creates a new Person, even if the
# name matches someone else globally. This trades a false merge (two different real people
# silently collapsed -- hard to detect, and the reason Admin::People::ExplodePerson exists) for a
# false split (the same person recorded twice -- safe, correctable later via the existing admin
# merge tooling). See docs/adr/0010-mass-ingestion-disambiguation-scoped-not-global.md.
class RecordCandidatePerson
  def self.call(name:, scope_group:) = new(name:, scope_group:).call

  def initialize(name:, scope_group:)
    @name = People::RecordPerson.clean_name(name)
    @scope_group = scope_group
  end

  def call
    existing_scoped_member || Person.create!(name:)
  end

  private

  attr_reader :name, :scope_group

  def existing_scoped_member
    # TODO: using first feels fragile
    Person.where(name:).joins(:groups).where(groups: { id: scope_group.id }).first
  end
end
