class Common::ExternalIdentifiersTable < ApplicationView
  attr_reader :external_identifiers

  def initialize(external_identifiers:)
    @external_identifiers = external_identifiers
  end

  def view_template
    return if external_identifiers.none?

    div(class: 'mb-3 w-100') do
      h6 { 'External IDs' }
      table(class: 'table table-sm table-bordered bg-white') do
        thead do
          tr do
            th { 'Source' }
            th { 'Value' }
          end
        end
        tbody do
          external_identifiers.each do |external_identifier|
            tr do
              td { external_identifier.source }
              td { external_identifier.value }
            end
          end
        end
      end
    end
  end
end
