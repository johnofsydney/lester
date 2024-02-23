class Home::TodoView < ApplicationView
  def initialize
  end

  def template
    div(class: 'container') do
      div(class: 'row', id: 'todo') do
        h2 { a(href: '/home/index') { 'Home' } }
        h2 { 'TODO:' }
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'Done' }
              ul do
                li { s{'Transfer Show Page'} }
                li { s{'Import Other Years'} }
                li { s{'Refine Group name Mapping'} }
                li { s{'Source Tree access for home'} }
                li { s{'Use affiliations, allow smaller grouping for state branches etc'} }
                li { s{'Use date range for memberships'} }
                li { s{ 'Several Roles for a membership (different titles) new model, remove title from membership itself' } }
                li { s{ 'Search' } }

              end
            end
          end
        end
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'Doing' }
              ul do
                li { 'Add Devise' }
                li { 'Add User Roles' }
              end
            end
          end
        end
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'TODO' }
              ul do
                li { 'CRUD for People, Groups and Transfers' }
                li { 'Phlex forms' }
                li { 'Better Use of Phlex, components' }
                li { 'Documentation / Content' }
                li { 'Theme / Color Scheme' }
                li { 'Faster Search ' }
                  ul do
                    li { 'https://mnishiguchi-2019.netlify.app/2019/01/29/rails-postgresql-trigram-search/' }
                  end
                li { 'What is a Transaction?' }
                li { 'D3 JS' }
                li { 'Shortest Path between any two nodes (include_looser_nodes)' }
                li { 'Deployment' }
                li { 'Tests' }
                li { 'Get ASX data programatically' }
                li { 'Node Linker - should consider memberships only? (Not affiliations)' }
                li { 'Node Linker - should consider overlapping memberships only?' }
                li { 'Node Linker - should consider several paths' }
                li { 'Node Linker - surface' }
                li { 'Several Memberships one person in one group' }
                li { 'Pagination' }
                li { 'Affiliations need start and end times as well' }
                li { 'More tests for record transfer taker' }
                li { 'Javascript' }
                li { 'jQuery' }
                li { 'Import Maps' }
                li { 'Import Phlex JS' }
                li { 'Import People / Groups / Positions from CSV' }
                li { 'Add Active Admin to edit all fields' }
                li { 'Add Audit table' }


                li { 'Add $$ totals on group and person page, by year' }
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