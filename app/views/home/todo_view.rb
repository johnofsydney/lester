class Home::TodoView < ApplicationView
  def initialize
  end

  def template
    div(class: 'container') do
      div(class: 'row', id: 'todo') do
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
                li { s{'CRUD for People, Groups and Transfers'} }
                li { s{'Deploy' } }
                li { s{'Add Devise' } }
                li { s{'Add AdminUsers / Active Admin to edit all fields' } }
                li { s{'Node Linker - surface' } }
                li { s{'Make memberships for groups' } }
                li { s{'Several Memberships one person in one group'} }
                li { s{'New Server'} }
                li { s{'Domain name'} }
              end
            end
          end
        end
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'Doing' }
              ul do
                li { 'Auto Deployment' }
                li { 'Write tests for Build Queue service and attend to TODOs' }
                li { 'Node Linker - should consider memberships only? (Not affiliations)' }
                li { 'Node Linker - should consider overlapping memberships only?' }
                li { 'Node Linker - should consider several paths' }
                li { 'Node Linker - use BuildQueue class' }
              end
            end
          end
        end
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'TODO' }
              ul do
                li { 'Add evidence to each model, as an Array' }
                li { 'Better Use of Phlex, components' }
                li { 'Documentation / Content' }
                li { 'Theme / Color Scheme' }

                li { 'D3 JS' }
                li { 'Shortest Path between any two nodes (include_looser_nodes)' }

                li { 'Tests' }
                li { 'Get ASX data programatically' }


                li { 'Pagination' }
                li { 'More tests for record transfer taker' }
                li { 'Javascript' }
                li { 'jQuery' }
                li { 'Import Maps' }
                li { 'Import Phlex JS' }
                li { 'Import People / Groups / Positions from CSV' }
                li { 'Add Indexes' }
                li { 'Add Audit table' }


                li { 'Add $$ totals on group and person page, by year' }
              end
            end
          end
        end
      end
    end
  end
end