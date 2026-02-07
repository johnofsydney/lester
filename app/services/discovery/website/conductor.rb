class Discovery::Website::Conductor
  def call
    # group_name = 'Club Marconi'
    # group = RecordGroup.call(group_name)

    # marconi = {
    #   people_card_selector: '.ede_detail', name_selector: 'h5', title_selector: 'p'
    # }

    # url = 'https://www.clubmarconi.com.au/your-club/board-of-directors/'
    # args = marconi

    # group = Group.find_by(name: 'Prime Super Pty Ltd')
    # url = 'https://www.primesuper.com.au/who-we-are/board'
    # args = {
    #   people_card_selector: '.staffpage .staff-container .staff .content',
    #   name_selector: 'h3',
    #   title_selector: 'p.staff-position'
    # }
    # group = Group.find_by(name: 'National Transport Insurance')
    # url = 'https://www.nti.com.au/who-we-are/executive-team'
    # args = {
    #   people_card_selector: '.c-executives__item',
    #   name_selector: '.c-executives__name',
    #   title_selector: '.c-executives__position'
    # }
    group = Group.find_by(name: 'Ethical Super Australia Limited')
    url = 'https://www.australianethical.com.au/about/executive-leadership/'
    args = {
      people_card_selector: '.lightBoxBlock-item-text-wrapper',
      name_selector: '.lightBoxBlock-item-heading',
      title_selector: '.lightBoxBlock-item-blurb'
    }

    page = Discovery::Website::PageDownloader.new.call(url)
    people = Discovery::Website::PageParser.new.call(page:, **args)

    people.each do |person_data|
      name = person_data[:name]
      title = person_data[:title]

      person = RecordPerson.call(name)
      membership = Membership.find_or_create_by(group:, member: person)
      Position.find_or_create_by(membership:, title:)
    end
  end
end
