class Home::MakeSuggestionView < ApplicationView
  def initialize
  end

  def template
    div(id: 'suggestions') do
      p { 'Send us a suggestion...' }
      p { 'The effectiveness of this application relies on having comprehensive data, and if you know of a person or group of interest please let us know' }
      p { 'Similarly if you know of an interesting transfer of funds from one entity to another, again, please let us know' }
      p do
        plain 'Any addition to our database'
        strong {' must '}
        plain 'be backed by publicly available evidence, so please include a link to that in your submission'
      end
      form(action: '/home/post_suggestions', enctype: "multipart/form-data", method: 'post') do
        div(class: "form-group") do
          label(for: "headline") { "Headline" }
          input(class: "form-control", type: "text", autofocus: true, name: "headline")
        end
        div(class: "form-group") do
          label(for: "description") { "Description" }
          textarea(class: "form-control", name: "description")
        end
        div(class: "form-group") do
          label(for: "evidence") { "Evidence" }
          input(class: "form-control", type: "text", name: "evidence", required: true)
        end
        div(class: "form-group") do
          label(for: "suggested_by") { "Your Email (Optional)" }
          input(class: "form-control", type: "text", name: "suggested_by")
        end


        button(class: "btn btn-primary margin-above", type: "submit") { "Submit" }
      end
    end
  end
end
