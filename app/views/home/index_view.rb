# class Home::IndexView < ApplicationView
#   def initialize
#   end

#   def template
#     div(class: 'jumbotron', style: 'background-color: #243447; color: white;') do
#       h1(class: 'display-4') { '...follow the money...' }
#     end

#     div(class: 'row margin-above') do
#       p do
#         strong { "Join The Dots" }
#         plain " is a platform dedicated to illuminating the web of connections between people, organisations and money."
#       end

#       p { "At the core of Join The Dots are three main components: People, Groups, and Transfers." }

#       p { "People are individuals who may belong to one or more groups. They may be involved in political donations and decision-making processes, or maybe not." }

#       p { "Groups encompass a variety of entities, including Companies, Political Parties, Schools, Churches, and any other grouping of people. Some of these groups play a direct role in shaping political outcomes and policies. Some are not involved at all." }

#       p { "Transfers are the movements of money that underpin political activities. This includes political donations, government grants, contracts for the supply of goods and services, salaries, and more." }

#       p do
#         "At Join The Dots, we track and aggregate publicly available political donations from the Australian Electoral Commission (AEC) website, organizing them by year. We also record all individuals and groups involved in making donations, as well as the recipient groups. We currently store;"
#       end

#       ul(style: 'list-style-type: none;') do
#         li { a(href: 'https://transparency.aec.gov.au/AnnualDonor') { 'AEC Annual Donor records since 2018' } }
#         li { a(href: 'https://transparency.aec.gov.au/ReferendumDonor') { 'AEC 2023 Referendum Donor Returns' } }
#         li { a(href: 'https://transparency.aec.gov.au/Donor') { 'AEC Election Donor Returns since 2007' } }
#         li { a(href: 'https://en.wikipedia.org/wiki/Category:Members_of_Australian_parliaments_by_term') { 'Federal MPs and Senators since 2016' } }
#         li { 'The following Ministries' }
#         li do

#           ul do
#             li { a(href: 'https://en.wikipedia.org/wiki/First_Rudd_ministry') { 'Rudd Government' } }
#             li { a(href: 'https://en.wikipedia.org/wiki/Second_Gillard_ministry') { 'Gillard Government' } }
#             li { a(href: 'https://en.wikipedia.org/wiki/Abbott_ministry') { 'Abbott Government' } }
#             li { a(href: 'https://en.wikipedia.org/wiki/First_Turnbull_ministry') { 'Turnbull Government' } }
#             li { a(href: 'https://en.wikipedia.org/wiki/First_Morrison_ministry') { 'Morrison Government' } }
#             li { a(href: 'https://en.wikipedia.org/wiki/Albanese_ministry') { 'Albanese Government' } }
#           end
#         end
#         li { a(href: 'https://www.parliament.nsw.gov.au/members/pages/all-members.aspx') { 'Current Members of the NSW Parliament (2025)' } }
#         li { a(href: 'https://www.parliament.nsw.gov.au/members/formermembers/Pages/former-members.aspx') { 'Former Members of the NSW Parliament (except deceased members)' } }
#         li { a(href: 'https://lobbyists.ag.gov.au/register') { 'Lobbyists and the Clients Of Lobbyists' } }
#       end

#       p { "For groups where the owners, major shareholders, or key personnel can be identified through public records, we add these individuals to the group in our database. This enhances the depth and accuracy of our data, providing a more comprehensive view of the connections of the individual." }

#       p { "It's important to note that everything on our website is backed by publicly available information. We do not conduct any original research; rather, we aggregate, format, and arrange the data to reveal underlying patterns and connections. Join The Dots is committed to transparency, accountability and ensuring access to information." }
#     end
#     p do
#       a(href: 'https://bsky.app/profile/join-the-dots.info') { 'join-the-dots.info on Bluesky' }
#     end
#     p do
#       a(href: 'mailto:jointhedots.au@protonmail.com') { 'jointhedots.au@protonmail.com' }
#     end
#   end
# end

class Home::IndexView < ApplicationView
  def template
    div(class: "bg-dark text-white p-5 mb-4 rounded-3") do
      h1(class: "display-4 mb-0") { "...follow the money..." }
    end

    div(class: "container") do
      div(class: "row justify-content-center") do
        div(class: "col") do

          p do
            strong { "Join The Dots" }
            plain " is a platform dedicated to illuminating the web of connections between people, organisations and money."
          end


          div(class: "card shadow-sm mb-4") do
            div(class: "card-body") do
              p { "At the core of Join The Dots are three main components: People, Groups, and Transfers." }

              p { "People are individuals who may belong to one or more groups. They may be involved in political donations and decision-making processes, or maybe not." }

              p { "Groups encompass a variety of entities, including Companies, Political Parties, Schools, Churches, and any other grouping of people. Some of these groups play a direct role in shaping political outcomes and policies. Some are not involved at all." }

              p { "Transfers are the movements of money that underpin political activities. This includes political donations, government grants, contracts for the supply of goods and services, salaries, and more." }
            end
          end
          div(class: "card shadow-sm mb-4") do
            div(class: "card-body") do
              p do
                "At Join The Dots, we track and aggregate publicly available political donations from the Australian Electoral Commission (AEC) website, organizing them by year. We also record all individuals and groups involved in making donations, as well as the recipient groups. We currently store:"
              end

              ul(class: "list-unstyled") do
                li { a(href: 'https://transparency.aec.gov.au/AnnualDonor', class: "d-block mb-1") { 'AEC Annual Donor records since 2018' } }
                li { a(href: 'https://transparency.aec.gov.au/ReferendumDonor', class: "d-block mb-1") { 'AEC 2023 Referendum Donor Returns' } }
                li { a(href: 'https://transparency.aec.gov.au/Donor', class: "d-block mb-1") { 'AEC Election Donor Returns since 2007' } }
                li { a(href: 'https://en.wikipedia.org/wiki/Category:Members_of_Australian_parliaments_by_term', class: "d-block mb-1") { 'Federal MPs and Senators since 2016' } }
                li(class: "fw-bold mt-3") { 'The following Ministries:' }
                li do
                  ul(class: "list-unstyled ms-3") do
                    li { a(href: 'https://en.wikipedia.org/wiki/First_Rudd_ministry') { 'Rudd Government' } }
                    li { a(href: 'https://en.wikipedia.org/wiki/Second_Gillard_ministry') { 'Gillard Government' } }
                    li { a(href: 'https://en.wikipedia.org/wiki/Abbott_ministry') { 'Abbott Government' } }
                    li { a(href: 'https://en.wikipedia.org/wiki/First_Turnbull_ministry') { 'Turnbull Government' } }
                    li { a(href: 'https://en.wikipedia.org/wiki/First_Morrison_ministry') { 'Morrison Government' } }
                    li { a(href: 'https://en.wikipedia.org/wiki/Albanese_ministry') { 'Albanese Government' } }
                  end
                end
                li { a(href: 'https://www.parliament.nsw.gov.au/members/pages/all-members.aspx') { 'Current Members of the NSW Parliament (2025)' } }
                li { a(href: 'https://www.parliament.nsw.gov.au/members/formermembers/Pages/former-members.aspx') { 'Former Members of the NSW Parliament (except deceased members)' } }
                li { a(href: 'https://lobbyists.ag.gov.au/register') { 'Lobbyists and the Clients Of Lobbyists' } }
              end
            end
          end
          div(class: "card shadow-sm mb-4") do
            div(class: "card-body") do
              p { "For groups where the owners, major shareholders, or key personnel can be identified through public records, we add these individuals to the group in our database. This enhances the depth and accuracy of our data, providing a more comprehensive view of the connections of the individual." }

              p { "It's important to note that everything on our website is backed by publicly available information. We do not conduct any original research; rather, we aggregate, format, and arrange the data to reveal underlying patterns and connections. Join The Dots is committed to transparency, accountability and ensuring access to information." }


            end
          end
        end
      end

      div(class: "row justify-content-center") do
        div(class: "col") do
          hr(class: "my-4")

          p { a(href: 'https://bsky.app/profile/join-the-dots.info', class: "text-decoration-none") { 'join-the-dots.info on Bluesky' } }
          # p { a(href: 'mailto:jointhedots.au@protonmail.com', class: "text-decoration-none") { 'jointhedots.au@protonmail.com' } }
        end
      end
    end
  end
end
