class Home::IndexView < ApplicationView
  def initialize
  end

  def template
    div(class: 'jumbotron', style: 'background-color: #243447; color: white;') do
      h1(class: 'display-4') { '...follow the money...' }
    end

    div(class: 'row') do
      p do
        strong { "Join The Dots" }
        plain " is a platform dedicated to illuminating the web of connections between people, organisations and money."
      end

      p { "At the core of Join The Dots are three main components: People, Groups, and Transfers." }

      p { "People are individuals who may belong to one or more groups. They may be involved in political donations and decision-making processes, or maybe not." }

      p { "Groups encompass a variety of entities, including Companies, Political Parties, Schools, Churches, and any other grouping of people. Some of these groups play a direct role in shaping political outcomes and policies. Some are not involved at all." }

      p { "Transfers are the movements of money that underpin political activities. This includes political donations, government grants, contracts for the supply of goods and services, salaries, and more." }

      p do
        "At Join The Dots, we track and aggregate publicly available political donations from the Australian Electoral Commission (AEC) website, organizing them by year. We also record all individuals and groups involved in making donations, as well as the recipient groups. We currently store;"
      end

      ul(style: 'list-style-type: none;') do
        li do
          a(href: 'https://transparency.aec.gov.au/AnnualDonor') { 'AEC Annual Donor records for the last 5 years' }
        end
      end


      p { "For groups where the owners, major shareholders, or key personnel can be identified through public records, we add these individuals to the group in our database. This enhances the depth and accuracy of our data, providing a more comprehensive view of the connections of the individual." }

      p { "It's important to note that everything on our website is backed by publicly available information. We do not conduct any original research; rather, we aggregate, format, and arrange the data to reveal underlying patterns and connections. Join The Dots is committed to transparency, accountability andf ensuring access to information." }
    end
    p do
      a(href: 'https://twitter.com/jointhedots_au/') { '@jointhedots_au' }
    end
  end
end