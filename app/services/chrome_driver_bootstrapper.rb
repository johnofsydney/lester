# frozen_string_literal: true

class ChromeDriverBootstrapper
  MAX_ATTEMPTS = 3
  PORT_RANGE   = (9515..9600)

  def initialize(logger: Rails.logger)
    @logger = logger
  end

  def launch
    attempts = 0

    begin
      attempts += 1
      @logger.info "Launching ChromeDriver (attempt #{attempts}/#{MAX_ATTEMPTS})"

      port = pick_free_port
      @logger.info "Selected ChromeDriver port #{port}"

      cleanup_stale_processes

      service = start_service(port)

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

      raise RuntimeError, "Failed to launch Selenium ChromeDriver after #{MAX_ATTEMPTS} attempts: #{e.message}"
    end
  end

  private

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

  def cleanup_stale_processes
    @logger.info "Cleaning up stale ChromeDriver/Chrome processes..."
    %w[chromedriver chromium-browser chrome google-chrome chromium].each do |bin|
      system("pkill -f #{bin} >/dev/null 2>&1 || true")
    end
  end

  #
  # FIXED: universal ChromeDriver service builder
  #
  def start_service(port)
    Selenium::WebDriver::Chrome::Service.new(
      port: port,
      args: ["--port=#{port}"]
    ).tap(&:start)
  end

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
