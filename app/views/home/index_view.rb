class Home::IndexView < ApplicationView
  def view_template
    div(class: 'bg-dark text-white p-5 mb-4 rounded-3') do
      h1(class: 'display-4 mb-0') { '...follow the money...' }
    end

    div(class: 'container') do
      div(class: 'row justify-content-center') do
        div(class: 'col') do

          p do
            strong { 'Join The Dots' }
            plain ' is a platform dedicated to illuminating the web of connections between people, organisations and money.'
          end

          div(class: 'card shadow-sm mb-4') do
            div(class: 'card-body') do
              p { 'At the core of Join The Dots are three main components: People, Groups, and Transfers.' }

              p { 'People are individuals who may belong to one or more groups. They may be involved in political donations and decision-making processes, or maybe not.' }

              p { 'Groups encompass a variety of entities, including Companies, Political Parties, Schools, Churches, Clubs, and any other grouping of people. Some of these groups play a direct role in shaping political outcomes and policies. Some are not involved at all.' }

              p { 'Transfers are the movements of money that underpin political activities. This includes political donations, government grants, contracts for the supply of goods and services, salaries, and more.' }
            end
          end
          div(class: 'card shadow-sm mb-4') do
            div(class: 'card-body') do
              p do
                'At Join The Dots, we track and aggregate publicly available political donations from the Australian Electoral Commission (AEC) website, organizing them by year. We also record all individuals and groups involved in making donations, as well as the recipient groups. We currently store:'
              end

              table(class: 'table table-striped') do
                thead do
                  tr do
                    th { 'Data Source' }
                    th { 'Notes' }
                  end
                end
                tbody do
                  tr do
                    td { a(href: 'https://transparency.aec.gov.au/AnnualDonor') { 'AEC Annual Donor records since 1999' } }
                    td { plain 'manual trigger' }
                  end
                  tr do
                    td { a(href: 'https://transparency.aec.gov.au/ReferendumDonor') { 'AEC 2023 Referendum Donor Returns' } }
                    td { plain 'manual trigger' }
                  end
                  tr do
                    td { a(href: 'https://transparency.aec.gov.au/Donor') {'AEC Election Donor Returns Since 2007'} }
                    td { plain 'manual trigger' }
                  end
                  tr do
                    td { a(href: 'https://www.tenders.gov.au/cn/search') { 'Federal Government Contracts since 2018' } }
                    td { plain 'automatically ingested daily'}
                  end
                  tr do
                    td { a(href: 'https://lobbyists.ag.gov.au/register') { 'Lobbyists and the Clients Of Lobbyists' } }
                    td { plain 'automatically ingested every 6 months'}
                  end
                  tr do
                    td { a(href: 'https://www.acnc.gov.au/', class: 'd-block mb-1') { 'Charities and Not-For-Profit Organisations' } }
                    td { plain 'automatically ingested every 6 months' }
                  end
                  tr do
                    td { a(href: 'https://en.wikipedia.org/wiki/Category:Members_of_Australian_parliaments_by_term') { 'Federal MPs and Senators since 2016' } }
                    td { plain 'manually ingested. (data for the 2025 election results yet to be collated and added to the database)' }
                  end
                  tr do
                    td { plain 'Various Ad-Hoc Data Sources added directly' }
                    td { plain 'manually ingested as needed' }
                  end
                end
              end
            end
          end
          div(class: 'card shadow-sm mb-4') do
            div(class: 'card-body') do
              p { 'For groups where the owners, major shareholders, or key personnel can be identified through public records, we add these individuals to the group in our database. This enhances the depth and accuracy of our data, providing a more comprehensive view of the connections of the individual.' }

              p { "It's important to note that everything on our website is backed by publicly available information. We do not conduct any original research; rather, we aggregate, format, and arrange the data to reveal underlying patterns and connections. Join The Dots is committed to transparency, accountability and ensuring access to information." }

              p { "Categorising groups and people isn't always straightforward. A large group may have transfers that are associated with different categories. We will tag the Group with each relevant category to provide a comprehensive view of the group's activities. When you view the Category data, it will show all of the money transfers in and out relating to those Groups in the category. Not all of their transfers will necessarily fall into a single category." }
            end
          end
        end
      end

      div(class: 'row justify-content-center') do
        div(class: 'col') do
          hr(class: 'my-4')

          p { a(href: 'https://bsky.app/profile/join-the-dots.info', class: 'text-decoration-none') { 'join-the-dots.info on Bluesky' } }
          # p { a(href: 'mailto:jointhedots.au@protonmail.com', class: "text-decoration-none") { 'jointhedots.au@protonmail.com' } }
        end
      end
    end
  end
end
