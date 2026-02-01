class AnyWebsite::PageParser
  def call(page:, people_card_selector:, name_selector:, title_selector:)
    doc = Nokogiri::HTML(page)

    doc.css(people_card_selector)
       .map do |person|
      name = person.css(name_selector).text.strip
      title = person.css(title_selector).text.strip

      { name:, title: }
    end
  end
end
