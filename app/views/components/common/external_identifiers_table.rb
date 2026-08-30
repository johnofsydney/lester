class Common::ExternalIdentifiersTable < ApplicationView
  attr_reader :external_identifiers

  def initialize(external_identifiers:)
    @external_identifiers = external_identifiers
  end

  def view_template
    return if external_identifiers.none?

    div(class: 'p-3 bg-white rounded shadow-sm border mb-2 w-100') do
      p(class: 'text-muted small text-uppercase fw-bold mb-2') { 'External IDs' }
      table(class: 'table table-sm table-borderless mb-0 align-middle') do
        tbody do
          external_identifiers.each do |external_identifier|
            tr do
              td(class: 'py-1 pe-2 text-secondary-emphasis fw-bold text-uppercase', style: 'font-size: 0.75em;') { external_identifier.source }
              td(class: 'py-1 text-break', style: 'font-size: 0.75em;') { external_identifier.value }
            end
          end
        end
      end
    end
  end
end
