class Exports::S3Client
  attr_reader :bucket, :client

  def initialize
    @bucket = Rails.application.credentials.dig(:aws, :s3_export_bucket)
    @client = Aws::S3::Client.new(
      region: Rails.application.credentials.dig(:aws, :region),
      access_key_id: Rails.application.credentials.dig(:aws, :access_key_id),
      secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key)
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
