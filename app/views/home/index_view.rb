class Home::IndexView < ApplicationView
  def initialize
  end

  def template
    div(class: 'container') do
      div(class: 'jumbotron', style: 'background-color: #243447; color: white;') do
        h1(class: 'display-4') { 'Unveiling the Ties That Bind: Tracking Money in Politics' }
        h3(class: 'display-6') { 'Uncovering the Hidden Networks of Influence & Empowering Citizens with Transparency' }
        p(class: 'lead') { 'In the realm of politics, money talks. And often, it whispers secrets into the ears of those in power. At [website name], we shine a light on these shadowy interactions, exposing the potential for corruption that lurks beneath the surface of our political system.' }
      end

      div(class: 'row') do
        div(class: 'col-sm') do
          div(class: 'card h-100') do
            div(class: 'card-body d-flex flex-column justify-content-between') do
              h6(class: 'card-title') { 'Unveiling the People Behind the Political Influence' }
              p(class: 'card-text') { 'At the heart of our work lies a deep understanding of the individuals who wield power and influence in our political landscape. We delve into their financial dealings, uncovering their connections to donors, lobbyists, and special interests.' }
              a(href: '/people', class: 'btn btn-primary') { 'People' }
            end
          end
        end
        div(class: 'col-sm') do
          div(class: 'card h-100') do
            div(class: 'card-body d-flex flex-column justify-content-between') do
              h6(class: 'card-title') { 'Unmasking the Hidden Hands Behind Political Agendas' }
              p(class: 'card-text') { 'Beyond individual politicians, we also investigate the powerful groups that exert influence on our political system. From corporations to unions, we expose the hidden networks that shape policy decisions and impact our lives.' }
              a(href: '/groups', class: 'btn btn-primary') { 'Groups' }
            end
          end
        end
        div(class: 'col-sm') do
          div(class: 'card h-100') do
            div(class: 'card-body d-flex flex-column justify-content-between') do
              h6(class: 'card-title') { 'Tracking the Flow of Money in Politics' }
              p(class: 'card-text') { 'Money is the lifeblood of political campaigns and lobbying efforts. We track the flow of money, uncovering potential sources of corruption and revealing the extent to which special interests influence our political process.' }
              a(href: '/transfers', class: 'btn btn-primary') { 'Transfers' }
            end
          end
        end
      end

      div(class: 'row', id: 'todo') do
        h2 { 'TODO:' }
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'Work Laptop' }
              ul do
                li { 'Transfer Show Page' }
                li { 'Search' }
                li { 'What is a Transaction?' }
                li { 'D3 JS' }
                li { 'Shortest Path between any two nodes (include_looser_nodes)' }
                li { 'Use affiliations, allow smaller grouping for state branches etc' }
                li { 'Use date range for memberships' }
                li { 'Source Tree access for this repo' }
              end
            end
          end
        end
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'Home Laptop' }
              ul do
                li { 'CRUD for People, Groups and Transfers' }
                li { 'Phlex forms' }
                li { 'Better Use of Phlex, components' }
                li { 'Documentation / Content' }
                li { 'Theme / Color Scheme' }
                li { 'Import Other Years' }
                li { 'Refine Group name Mapping' }
                li { 'Deployment' }
                li { 'Tests' }
                li { 'Get ASX data programatically' }
                li { 'Source Tree access for home' }
              end
            end
          end
        end
      end

      footer(class: 'footer mt-auto py-3 bg-light') do
        div(class: 'container') do
          span(class: 'text-muted') { 'Place sticky footer content here.' }
        end
      end
    end
  end
end