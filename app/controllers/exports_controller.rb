class ExportsController < ApplicationController
  def index
    @objects = Exports::S3Client.list
    @zip_url = Exports::S3Client.public_url(Exports::S3Client::ZIP_KEY)
  end
end
