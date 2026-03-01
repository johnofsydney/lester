return if Rails.env.test? || Rails.env.production?

Transfer.destroy_all
Affiliation.destroy_all
Membership.destroy_all
Group.destroy_all
Person.destroy_all

john = Person.create(name: 'John')
mark = Person.create(name: 'Mark')
ben = Person.create(name: 'Ben')
paul = Person.create(name: 'Paul')
fox = Person.create(name: 'Richard Fox')
charles = Person.create(name: 'Charles')
richard = Person.create(name: 'Uncle Richard')

eddie = Person.create(name: 'Eddie')

alp = Group.create(name: 'Australian Labor Party')
aloyisus = Group.create(name: 'Aloyisus')
usyd = Group.create(name: 'University of Sydney')
balance = Group.create(name: 'Balance')
kennards = Group.create(name: 'Kennards')
greens_nsw = Group.create(name: 'The Greens NSW')
greens_federal = Group.create(name: 'The Greens Federal')
greens_vic = Group.create(name: 'The Greens Victoria')

Membership.create(group: alp, member: john, start_date: 2.years.ago)
Membership.create(group: alp, member: eddie, start_date: 25.years.ago, end_date: 10.years.ago)

Membership.create(group: usyd, member: john, start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, member: mark, start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, member: ben, start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, member: fox, start_date: 34.years.ago, end_date: 30.years.ago)

Membership.create(group: aloyisus, member: paul, start_date: 40.years.ago, end_date: 35.years.ago)
Membership.create(group: aloyisus, member: ben, start_date: 40.years.ago, end_date: 35.years.ago)
Membership.create(group: aloyisus, member: fox, start_date: 40.years.ago, end_date: 35.years.ago)

Membership.create(group: balance, member: paul, start_date: 16.years.ago)
Membership.create(group: kennards, member: fox, start_date: 6.years.ago)

Membership.create(group: greens_nsw, member: richard, start_date: 12.years.ago, end_date: 10.years.ago)
Membership.create(group: greens_vic, member: charles, start_date: 12.years.ago)

Transfer.create(giver: balance, taker: greens_nsw, amount: 1000, effective_date: 2.years.ago)
Transfer.create(giver: kennards, taker: greens_nsw, amount: 1000, effective_date: 2.years.ago)
Transfer.create(giver: paul, taker: alp, amount: 1000, effective_date: 20.years.ago)

Membership.create(group: greens_federal, member: greens_nsw, start_date: 20.years.ago)
Membership.create(group: greens_federal, member: greens_vic, start_date: 20.years.ago)
AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?