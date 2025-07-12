# require 'nokogiri'
# require 'open-uri'

class TenderIngestor
  def self.perform
    new.perform
  end

  def perform(url = nil, results = [], page = 0)
    url ||= 'https://api.tenders.gov.au/ocds/findByDates/contractPublished/2017-11-26T13:02:31Z/2017-11-27T13:02:31Z'


    # results = []
    # binding.pry
    response = download(url)
    # pages ||= 1
    body = response[:body]

    if response && body && body['releases']
      results << body['releases'].map do |release|
        {
          page: page,
          ocid: release['ocid'],
          date: release['date'],
          value: release['contracts'].first['value']['amount'],
        }
      end
    end

    if response && body && response[:next_page]
      page += 1
      puts ("Next page URL: #{response[:next_page]}".slice(0, 100))

      perform(response[:next_page], results, page)


    else
      puts "No more pages or an error occurred."
    end

    puts "Total pages processed: #{page}"

    results.compact.flatten

  end

  def download(url)
    conn = Faraday.new(url:)

    response = conn.get do |req|
      req.params['pretty'] = true
    end

    return unless response.success?

    body = JSON.parse(response.body)

    if body['links']['next'].present?
      # Fetch the next page of results
      print "Next page URL: #{body['links']['next']}"
      p body['links']['next']
    end

    {
      body: body,
      next_page: body['links']['next']
    }
  end
end
