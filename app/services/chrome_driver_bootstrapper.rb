# frozen_string_literal: true

class ChromeDriverBootstrapper
  MAX_ATTEMPTS = 3
  PORT_RANGE   = (9515..9600) # safe isolated range

  def initialize(logger: Rails.logger)
    @logger = logger
  end

  def launch
    attempts = 0

    begin
      attempts += 1
      @logger.info "Launching ChromeDriver (attempt #{attempts}/#{MAX_ATTEMPTS})"

      # 1) choose a free port
      port = pick_free_port
      @logger.info "Selected ChromeDriver port #{port}"

      # 2) cleanup stale processes
      cleanup_stale_processes

      # 3) start driver
      service = start_service(port)

      # 4) validate that it booted
      wait_until_ready(port)

      @logger.info "ChromeDriver successfully launched on port #{port}"
      service
    rescue StandardError => e
      @logger.error "ChromeDriver launch attempt #{attempts} failed: #{e.class} - #{e.message}"
      cleanup_stale_processes

      if attempts < MAX_ATTEMPTS
        sleep 1
        retry
      end

      # FINAL FAIL — re-raise so Sidekiq retries the job
      raise RuntimeError, "Failed to launch Selenium ChromeDriver after #{MAX_ATTEMPTS} attempts: #{e.message}"
    end
  end

  private

  # ------------------------------------------
  # Pick an available port
  # ------------------------------------------
  def pick_free_port
    PORT_RANGE.each do |port|
      begin
        TCPServer.open("127.0.0.1", port).close
        return port
      rescue Errno::EADDRINUSE
        next
      end
    end

    raise "No free ports available for ChromeDriver"
  end

  # ------------------------------------------
  # Clean up any stale Chrome/Chromedriver processes
  # ------------------------------------------
  def cleanup_stale_processes
    @logger.info "Cleaning up stale ChromeDriver/Chrome processes..."
    %w[chromedriver chromium-browser chrome google-chrome chromium].each do |bin|
      system("pkill -f #{bin} >/dev/null 2>&1 || true")
    end
  end

  # ------------------------------------------
  # Start selenium-webdriver service
  # ------------------------------------------
  def start_service(port)
    Selenium::WebDriver::Chrome::Service.builder
      .with_args("--port=#{port}")
      .build
      .tap(&:start)
  end

  # ------------------------------------------
  # Ensure ChromeDriver is actually ready
  # ------------------------------------------
  def wait_until_ready(port)
    Timeout.timeout(5) do
      loop do
        begin
          socket = TCPSocket.new("127.0.0.1", port)
          socket.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          sleep 0.1
        end
      end
    end
  rescue Timeout::Error
    raise "ChromeDriver did not respond on port #{port}"
  end
end
