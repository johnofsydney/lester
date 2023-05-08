# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Membership.destroy_all
Group.destroy_all
Person.destroy_all

john = Person.create(name: 'john')
mark = Person.create(name: 'mark')
paul = Person.create(name: 'paul')
ben = Person.create(name: 'ben')
frank = Person.create(name: 'frank')
richard_fox_smith = Person.create(name: 'richard fox smith')
hoon = Person.create(name: 'hoon')
dave = Person.create(name: 'dave')
matt_sheen = Person.create(name: 'matt sheen')
matt_teffer = Person.create(name: 'matt teffer')
ron_tallon = Person.create(name: 'ron tallon')
ron_clarke  = Person.create(name: 'ron clarke')
richard_salmon = Person.create(name: 'richard salmon')


wcbcc = Group.create(name: 'wcbcc')
usyd = Group.create(name: 'usyd')
aloysius = Group.create(name: 'aloysius')
bands = Group.create(name: 'bands')
phhs = Group.create(name: 'phhs')

Membership.create(person: john, group: wcbcc)
Membership.create(person: paul, group: wcbcc)
Membership.create(person: richard_fox_smith, group: wcbcc)
Membership.create(person: ben, group: wcbcc)

Membership.create(person: paul, group: aloysius)
Membership.create(person: ben, group: aloysius)
Membership.create(person: frank, group: aloysius)
Membership.create(person: richard_fox_smith, group: aloysius)

Membership.create(person: john, group: phhs)
Membership.create(person: dave, group: phhs)
Membership.create(person: matt_teffer, group: phhs)

Membership.create(person: hoon, group: usyd)
Membership.create(person: dave, group: usyd)
Membership.create(person: ben, group: usyd)
Membership.create(person: john, group: usyd)
Membership.create(person: mark, group: usyd)


Membership.create(person: hoon, group: bands)
Membership.create(person: dave, group: bands)
Membership.create(person: john, group: bands)
Membership.create(person: mark, group: bands)
Membership.create(person: matt_sheen, group: bands)
Membership.create(person: matt_teffer, group: bands)
Membership.create(person: ron_tallon, group: bands)
Membership.create(person: ron_clarke, group: bands)
Membership.create(person: richard_salmon, group: bands)

