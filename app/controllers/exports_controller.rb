class ExportsController < ApplicationController
  def index
    @objects = Exports::S3Client.list
  end
end
