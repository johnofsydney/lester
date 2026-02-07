class Discovery::Website::PageParser
  def self.call(page:, people_card_selector:, name_selector:, title_selector:)
    new(page:, people_card_selector:, name_selector:, title_selector:).call
  end

  def initialize(page:, people_card_selector:, name_selector:, title_selector:)
    @page = page
    @people_card_selector = people_card_selector
    @name_selector = name_selector
    @title_selector = title_selector
  end

  def call
    doc = Nokogiri::HTML(page)

    doc.css(people_card_selector).map { |person| extract_name_and_title(person) }
  end

  private

  attr_reader :page, :people_card_selector, :name_selector, :title_selector

  def extract_name_and_title(person)
      {
        name: person.css(name_selector).text.strip,
        title: person.css(title_selector).text.strip
      }
  end
end
