class Imports::AnnualAssociatedEntityView < Phlex::HTML
	def view_template
		h1 { 'Imports' }

      form(action: '/imports/annual_associated_entity_upload', enctype: 'multipart/form-data', method: 'post') do
        div(class: 'form-group') do
          label(for: 'project_title') { 'Title for your Project' }
          input(class: 'form-control', type: 'text', placeholder: 'Enter a title', name: 'project[title]', id:'project_title', value: 'My Title') { '' }
        end
        div(class: 'form-group') do
          input(class: 'form-control', type: 'file', value: 'filename', name: 'project[filename]') { '' }
        end

        button(class: 'btn btn-primary', type: 'submit') { 'Submit' }
      end
	end
end