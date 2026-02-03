class Discovery::Website::PageParser
  def self.call(page:, people_card_selector:, name_selector:, title_selector:)
    new.call(
      page:,
      people_card_selector:,
      name_selector:,
      title_selector:
    )
  end

  def call(page:, people_card_selector:, name_selector:, title_selector:)
    doc = Nokogiri::HTML(page)

    doc.css(people_card_selector).map{ |person| to_h(person, name_selector:, title_selector:)}
                                  .reject{ |person_data| person_data[:name].blank? && person_data[:title].blank?}
  end

  def to_h(person, name_selector:, title_selector:)
      name = person.css(name_selector).text.strip
      title = person.css(title_selector).text.strip

      { name:, title: }
  end
end
