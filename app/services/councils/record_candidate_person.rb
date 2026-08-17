# Resolves a council election candidate's name to a Person, scoped to this specific council --
# deliberately does NOT fall back to a bare global name match like People::RecordPerson does.
#
# NSWEC/VEC expose no per-candidate ID at all (confirmed live -- neither site's pages carry
# anything beyond name, party, and a per-ballot position that resets every contest), so there's no
# external_identifiers-style key to disambiguate on. A global "Person.find_by(name:)" is
# especially risky here: with ~200 councils and thousands of councillors nationwide, common names
# like "John Smith" are near-certain to collide across genuinely different people in different
# councils (or with an unrelated same-named Person from AEC/ACNC/OpenAustralia data).
#
# So candidate resolution only reuses an existing Person if they already have a Membership at
# THIS council (the returning-councillor case) -- otherwise it always creates a new Person, even
# if the name matches someone else globally. This trades a false merge (two different real people
# silently collapsed -- hard to detect, and the reason Admin::People::ExplodePerson exists) for a
# false split (the same person recorded twice -- safe, correctable later via the existing admin
# merge tooling).
class Councils::RecordCandidatePerson
  def self.call(name:, council:) = new(name:, council:).call

  def initialize(name:, council:)
    @name = People::RecordPerson.clean_name(name)
    @council = council
  end

  def call
    existing_council_member || Person.create!(name:)
  end

  private

  attr_reader :name, :council

  def existing_council_member
    # TODO: using first feels fragile
    Person.where(name:).joins(:groups).where(groups: { id: council.id }).first
  end
end
