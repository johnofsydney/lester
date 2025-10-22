class Home::MakeSuggestionView < ApplicationView
  def view_template
    div(id: 'suggestions') do
      p { 'Send us a suggestion...' }
      p { 'The effectiveness of this application relies on having comprehensive data, and if you know of a person or group of interest please let us know' }
      p { 'Similarly if you know of an interesting transfer of funds from one entity to another, again, please let us know' }
      p { 'Also, if you think we have something wrong, please let us know that too' }
      p do
        plain 'Any addition to our database'
        strong {' must '}
        plain 'be backed by publicly available evidence, so please include a link to that in your submission'
      end
      p do
        plain 'Contact us by DM at Bluesky: '
        a(href: 'https://bsky.app/profile/jointhedots.au') { 'jointhedots.au' }
      end
    end
  end
end
