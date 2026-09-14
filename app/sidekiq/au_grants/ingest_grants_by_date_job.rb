# Downloads the GrantConnect published-grants XLSX for a single publish date
# and fans out one IngestSingleGrantJob per row.

class AuGrants::IngestGrantsByDateJob
  include Sidekiq::Job

  sidekiq_options queue: :au_grants, retry: 5

  def perform(date_string = Date.yesterday.to_s)
    date = Date.parse(date_string)

    path = AuGrants::GrantsDownloader.new.call(date)

    begin
      AuGrants::XlsxParser.new.call(path).each do |row|
        AuGrants::IngestSingleGrantJob.perform_async(row)
      end
    ensure
      File.delete(path) if File.exist?(path)
    end
  rescue Faraday::ClientError, Faraday::ServerError => e
    Rails.logger.warn "Error downloading grants for #{date_string}: #{e.message} - will retry"
    raise e
  end
end
