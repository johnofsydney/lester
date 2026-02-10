class Imports::AnnualDonorForm < Phlex::HTML
  def view_template
    h1 { 'Imports' }

    div do
      h2 { 'Import AEC Annual Donor Data'}
      form(action: '/imports/annual_donor_upload', enctype: 'multipart/form-data', method: 'post') do
        div(class: 'form-group') do
          input(class: 'form-control', type: 'file', value: 'filename', name: 'project[filename]') { '' }
        end

        button(class: 'btn btn-primary', type: 'submit') { 'Submit' }
      end
    end

    div do
      h2 { 'Import Cleaned List of Federal Parliamentarians'}
      form(action: '/imports/federal_parliamentarians_upload', enctype: 'multipart/form-data', method: 'post') do
        div(class: 'form-group') do
          input(class: 'form-control', type: 'file', value: 'filename', name: 'project[filename]') { '' }
        end

        button(class: 'btn btn-primary', type: 'submit') { 'Submit' }
      end
    end

    div do
      h2 { 'Import Peoples Names'}
      form(action: '/imports/people_upload', enctype: 'multipart/form-data', method: 'post') do
        div(class: 'form-group') do
          input(class: 'form-control', type: 'file', value: 'filename', name: 'project[filename]') { '' }
        end

        button(class: 'btn btn-primary', type: 'submit') { 'Submit' }
      end
    end

    div do
      h2 { 'Import Groups Names'}
      form(action: '/imports/groups_upload', enctype: 'multipart/form-data', method: 'post') do
        div(class: 'form-group') do
          input(class: 'form-control', type: 'file', value: 'filename', name: 'project[filename]') { '' }
        end

        button(class: 'btn btn-primary', type: 'submit') { 'Submit' }
      end
    end
  end
end