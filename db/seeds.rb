
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


Membership.create(group: alp, person: john, title: 'Member', start_date: 2.years.ago)
Membership.create(group: alp, person: eddie, title: 'Member', start_date: 25.years.ago, end_date: 10.years.ago)

Membership.create(group: usyd, person: john, title: 'Student', start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, person: mark, title: 'Student', start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, person: ben, title: 'Student', start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, person: fox, title: 'Student', start_date: 34.years.ago, end_date: 30.years.ago)

Membership.create(group: aloyisus, person: paul, title: 'Student', start_date: 40.years.ago, end_date: 35.years.ago)
Membership.create(group: aloyisus, person: ben, title: 'Student', start_date: 40.years.ago, end_date: 35.years.ago)
Membership.create(group: aloyisus, person: fox, title: 'Student', start_date: 40.years.ago, end_date: 35.years.ago)

Membership.create(group: balance, person: paul, title: 'Owner', start_date: 16.years.ago)
Membership.create(group: kennards, person: fox, title: 'CIO', start_date: 6.years.ago)

Membership.create(group: greens_nsw, person: richard, title: 'Member', start_date: 12.years.ago, end_date: 10.years.ago)
Membership.create(group: greens_vic, person: charles, title: 'Member', start_date: 12.years.ago)

Transfer.create(giver: balance, taker: greens_nsw, amount: 1000, effective_date: 2.years.ago)
Transfer.create(giver: kennards, taker: greens_nsw, amount: 1000, effective_date: 2.years.ago)
Transfer.create(giver: paul, taker: alp, amount: 1000, effective_date: 20.years.ago)

Affiliation.create(owning_group: greens_federal, sub_group: greens_nsw, start_date: 20.years.ago)
Affiliation.create(owning_group: greens_federal, sub_group: greens_vic, start_date: 20.years.ago)
AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?