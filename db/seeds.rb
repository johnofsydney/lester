# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

john = Person.create(name: 'john')
mark = Person.create(name: 'mark')
paul = Person.create(name: 'paul')
ben = Person.create(name: 'ben')
frank = Person.create(name: 'frank')
richard = Person.create(name: 'richard')

wcbcc = Group.create(name: 'wcbcc')
usyd = Group.create(name: 'usyd')
school = Group.create(name: 'school')

Membership.create(person: john, group: wcbcc)
Membership.create(person: john, group: usyd)
Membership.create(person: mark, group: usyd)
Membership.create(person: paul, group: wcbcc)
Membership.create(person: paul, group: school)
Membership.create(person: ben, group: wcbcc)
Membership.create(person: ben, group: usyd)
Membership.create(person: ben, group: school)
Membership.create(person: frank, group: school)
Membership.create(person: richard, group: wcbcc)
Membership.create(person: richard, group: school)

