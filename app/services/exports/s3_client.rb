class Exports::S3Client
  ConfigurationError = Class.new(StandardError)

  attr_reader :bucket, :client

  def initialize
    credentials = Rails.application.credentials[:aws] || {}
    @bucket = credentials[:s3_export_bucket]

    missing = %i[s3_export_bucket region access_key_id secret_access_key].select { |key| credentials[key].blank? }
    raise ConfigurationError, "Missing Rails.application.credentials.aws keys: #{missing.join(', ')}" if missing.any?

    @client = Aws::S3::Client.new(
      region: credentials[:region],
      access_key_id: credentials[:access_key_id],
      secret_access_key: credentials[:secret_access_key]
    )
  end

  def self.upload(key, body)
    new.upload(key, body)
  end

  def upload(key, body)
    client.put_object(bucket: bucket, key: key, body: body)
  end

  def self.delete(key)
    new.delete(key)
  end

  def delete(key)
    client.delete_object(bucket: bucket, key: key)
  end

  def self.list
    new.list
  end

  # Objects sorted most-recently-modified first.
  def list
    objects.sort_by(&:last_modified).reverse
  end

  def self.public_url(key)
    new.public_url(key)
  end

  def public_url(key)
    "https://#{bucket}.s3.#{client.config.region}.amazonaws.com/#{key}"
  end

  private

  def objects
    client.list_objects_v2(bucket: bucket).contents
  end
end
