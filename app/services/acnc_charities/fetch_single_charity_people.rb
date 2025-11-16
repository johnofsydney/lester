require 'selenium-webdriver'

class AcncCharities::FetchSingleCharityPeople
  def self.perform(charity)
    new(charity).perform
  end

  def initialize(charity)
    @charity = charity
  end

  def perform
    # Part 1 - Go to the search page, search for the charity by ABN, get the UUID from the results
    conn = Faraday.new(url: search_url) do |config|
      config.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
      config.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
    end

    response = conn.get

    return { success: false, error: 'Request failed' } unless response.success?

    body = JSON.parse(response.body)
    return { success: false, error: 'No results found' } if body['results'].blank? || !body['results'].is_a?(Array) || body['results'][0].nil?
    @uuid = body['results'][0]['uuid']


    # Part 2 - Go to the people page for that charity UUID, scrape the people data using Selenium
    driver = setup_selenium_driver

    driver.get(people_url)

    # Wait for the Vue app to load
    wait = Selenium::WebDriver::Wait.new(timeout: 15)

    # Wait for people content to appear (adjust selector as needed)
    wait.until do
      driver.find_elements(css: '.charity-people').any?
    end

    # Give it a bit more time for all content to load
    sleep(1)

    cards = driver.find_elements(css: '.card-body')
    cards.each do |card|
      name = safe_text(card.find_elements(css: 'h4')[0])
      title = safe_text(card.find_elements(css: 'li')[0]).gsub('Role: ', '')

      person = RecordPerson.call(name)
      membership = Membership.find_or_create_by(group: @charity, member: person)
      Position.find_or_create_by(membership:, title:)

      Rails.logger.info("Recorded person: #{name} - #{title} to charity #{@charity.name}")
    end

    driver.quit
    { success: true, people_count: cards.count }
  ensure
    driver.quit if driver
  end

  def search_url
    "https://www.acnc.gov.au/api/dynamics/search/charity?search=#{@charity.business_number}"
  end

  def people_url
    "https://www.acnc.gov.au/charity/charities/#{@uuid}/people"
  end

  def setup_selenium_driver
    require 'selenium-webdriver'

    # Ensure no leftover Chrome/ChromeDriver processes interfere
    cleanup_chrome_processes

    options = Selenium::WebDriver::Chrome::Options.new

    # All current scraping-safe options preserved
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-extensions')
    options.add_argument('--disable-web-security')
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--remote-debugging-port=0') # ephemeral port
    options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36')
    options.add_argument('--disable-software-rasterizer')
    options.add_argument('--disable-features=VizDisplayCompositor')

    if RUBY_PLATFORM =~ /darwin/
      # Local Mac: default Chrome + Webdrivers auto-managed
      # Selenium::WebDriver.for(:chrome, options: options)
      # Local Mac: do nothing, default stable Chrome will be used
      # Webdrivers will auto-manage ChromeDriver
    else
      # Linux Graviton/ARM64
      chrome_bin = '/usr/bin/chromium-browser'
      chromedriver_bin = '/usr/lib/chromium-browser/chromedriver'

      raise "Chromium binary missing at #{chrome_bin}" unless File.exist?(chrome_bin)
      raise "ChromeDriver missing at #{chromedriver_bin}" unless File.exist?(chromedriver_bin)

      options.binary = chrome_bin

      service = Selenium::WebDriver::Service.chrome(
        path: chromedriver_bin,
        args: ['--verbose']
      )

      driver = nil
      3.times do |i|
        begin
          driver = Selenium::WebDriver.for(:chrome, options: options, service: service)
          break
        rescue Errno::ECONNREFUSED, Selenium::WebDriver::Error::WebDriverError => e
          Rails.logger.warn "Selenium startup failed (attempt #{i + 1}/3): #{e.message}"
          sleep 1
        end
      end

      raise "Failed to launch Selenium ChromeDriver after 3 attempts" unless driver

      driver
    end
  end

  def cleanup_chrome_processes
    # Kill any leftover ChromeDriver or Chromium processes
    %w[chromedriver chromium-browser google-chrome].each do |bin|
      system("pkill -f #{bin} || true")
    end
  end

  def safe_text(element)
    element.text.strip
  rescue StandardError
    ''
  end

  def safe_element_text(parent_element, selector)
    element = parent_element.find_element(css: selector)
    element.text.strip
  rescue Selenium::WebDriver::Error::NoSuchElementError
    ''
  end
end