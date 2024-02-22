class Home::IndexView < ApplicationView
  def initialize
  end

  def template
    div(class: 'container') do
      div(class: 'jumbotron', style: 'background-color: #243447; color: white;') do
        h1(class: 'display-4') { 'LESTER' }
        h3(class: 'display-6') { "you start to follow the money, and you don't know where the fuck it's gonna take you" }
        p(class: 'lead') { 'In the realm of politics, money talks. And often, it whispers secrets into the ears of those in power. Lester aims to highlight connections between individuals, organisations and money' }
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

        a(href: '/home/todo') { 'TODO' }
      end

      footer(class: 'footer mt-auto py-3 bg-light') do
        div(class: 'container') do
          span(class: 'text-muted') { 'Place sticky footer content here.' }
        end
      end
    end
  end
end