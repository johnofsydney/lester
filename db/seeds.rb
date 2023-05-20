
# Membership.destroy_all
# Group.destroy_all
# Person.destroy_all

# Transaction.destroy_all

federal_government = Group.create(name: 'Australian Federal Government')

guide_dogs_victoria = Group.create(name: 'Guide Dogs Victoria')

the_coalition = Group.find_by(name: 'The Coalition')
josh_frydenburg = Person.create(name: 'Josh Frydenburg')

paul_wheelton = Person.find_by(name: 'Paul Wheelton')

Membership.create(group: federal_government, person: josh_frydenburg)
Membership.create(group: the_coalition, person: josh_frydenburg)

Membership.create(group: guide_dogs_victoria, person: paul_wheelton, title: 'Capital Campaign Chair')

Transfer.create(
  giver: federal_government,
  taker: guide_dogs_victoria,
  start_date: Date.new(2020, 4, 1),
  end_date: Date.new(2020, 4, 1),
  amount: 25_000_000,
  transfer_type: 'grant',
  evidence: 'https://parlinfo.aph.gov.au/parlInfo/download/media/pressrel/7303441/upload_binary/7303441.pdf;fileType=application/pdf#search=%22media/pressrel/7303441%22'
)


atlassian = Group.create(name: 'Atlassian')

