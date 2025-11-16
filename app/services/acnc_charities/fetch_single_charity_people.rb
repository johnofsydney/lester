# frozen_string_literal: true
require 'selenium-webdriver'

class AcncCharities::FetchSingleCharityPeople
  def self.perform(charity)
    new(charity).perform
  end

  def initialize(charity)
    @charity = charity
  end

  def perform
    # Part 1 - query API for UUID
    conn = Faraday.new(url: search_url) do |config|
      config.headers['User-Agent'] = user_agent
      config.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
    end

    response = conn.get
    return { success: false, error: 'Request failed' } unless response.success?

    body = JSON.parse(response.body)
    if body['results'].blank? || !body['results'].is_a?(Array) || body['results'][0].nil?
      return { success: false, error: 'No results found' }
    end

    @uuid = body['results'][0]['uuid']

    # Part 2 - Selenium scraping
    driver = nil
    people_count = 0

    begin
      driver = setup_selenium_driver

      driver.get(people_url)

      wait = Selenium::WebDriver::Wait.new(timeout: 15)
      wait.until { driver.find_elements(css: '.charity-people').any? }

      sleep 1 # extra time for client-side rendering

      cards = driver.find_elements(css: '.card-body')
      cards.each do |card|
        name = safe_text(card.find_elements(css: 'h4')[0])
        title = safe_text(card.find_elements(css: 'li')[0]).gsub('Role: ', '')

        person = RecordPerson.call(name)
        membership = Membership.find_or_create_by(group: @charity, member: person)
        Position.find_or_create_by(membership:, title:)

        Rails.logger.info("Recorded person: #{name} - #{title} to charity #{@charity.name}")
        people_count += 1
      end

      { success: true, people_count: people_count }
    rescue StandardError => e
      Rails.logger.error "Error during Selenium scraping for charity_id=#{@charity.id}: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e # let Sidekiq retry according to policy
    ensure
      begin
        driver&.quit
      rescue StandardError => e
        Rails.logger.warn "Error while quitting Selenium driver: #{e.class} - #{e.message}"
      end
    end
  end

  private

  def search_url
    "https://www.acnc.gov.au/api/dynamics/search/charity?search=#{@charity.business_number}"
  end

  def people_url
    "https://www.acnc.gov.au/charity/charities/#{@uuid}/people"
  end

  def user_agent
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
  end

  def setup_selenium_driver
    # make sure selenium-webdriver loaded
    require 'selenium-webdriver'

    # Run cleanup - ChromeDriverBootstrapper also performs cleanup when launching,
    # but we call this early to reduce leftover processes interfering.
    cleanup_chrome_processes

    options = Selenium::WebDriver::Chrome::Options.new

    # preserve all your options
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-extensions')
    options.add_argument('--disable-web-security')
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--remote-debugging-port=0') # ephemeral port where possible
    options.add_argument("--user-agent=#{user_agent}")
    options.add_argument('--disable-software-rasterizer')
    options.add_argument('--disable-features=VizDisplayCompositor')

    if RUBY_PLATFORM.match?(/darwin/)
      # Local Mac: Webdrivers gem will manage chromedriver; return driver directly
      return Selenium::WebDriver.for(:chrome, options: options)
    end

    # Linux (ARM64/Graviton) branch: use your bootstrapper to start chromedriver reliably
    service = ChromeDriverBootstrapper.new.launch

    Selenium::WebDriver.for(:chrome, options: options, service: service)
  end

  def cleanup_chrome_processes
    # Best-effort kill of any lingering processes (no exceptions raised)
    %w[chromedriver chromium-browser google-chrome chromium chrome].each do |bin|
      system("pkill -f #{bin} >/dev/null 2>&1 || true")
    end
  end

  def safe_text(element)
    element&.text.to_s.strip
  rescue StandardError
    ''
  end

  def safe_element_text(parent_element, selector)
    element = parent_element.find_element(css: selector)
    element.text.strip
  rescue Selenium::WebDriver::Error::NoSuchElementError, StandardError
    ''
  end
end
