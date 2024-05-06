# require 'csv'

# class ImportsController < ApplicationController
#   # before_action :authenticate_user!
#   layout -> { ApplicationLayout }

#   def annual_associated_entity
#     render Imports::AnnualAssociatedEntityView.new
#   end

#   def index
#     # return unless current_user

#     render Imports::AnnualDonorForm.new
#   end

#   def annual_donor_upload
#     # return unless current_user

#     file = params['project']['filename'].tempfile

#     FileIngestor.annual_donor_ingest(file)

#     redirect_to groups_path
#   end

#   def federal_parliamentarians_upload
#     file = params['project']['filename'].tempfile

#     FileIngestor.federal_parliamentarians_upload(file)

#     redirect_to groups_path
#   end

#   def people_upload
#     return unless current_user

#     file = params['project']['filename'].tempfile

#     csv = CSV.read(file, headers: true)
#     csv.each do |row|
#       person = Person.find_or_create_by(name: row['Name'].titleize)

#       person.save
#     end

#     redirect_to people_path
#   end

#   def groups_upload
#     return unless current_user

#     file = params['project']['filename'].tempfile

#     csv = CSV.read(file, headers: true)
#     csv.each do |row|
#       group = Group.find_or_create_by(name: row['Name'].titleize)

#       group.save
#     end

#     redirect_to groups_path
#   end

#   def memberships_upload
#   end

#   private

#   def infer_date(row)
#     begin
#       Date.parse(row['Date'])
#     rescue => exception
#       Date.new( "20#{row['Financial Year'].last(2)}".to_i, 6, 30)
#     end
#   end

#   def parse_date(date)
#     begin
#       Date.parse(date)
#     rescue => exception
#       nil
#     end
#   end
# end

