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
                li { 'Transfer Show Page'}
                li { 'Import Other Years'}
                li { 'Refine Group name Mapping'}
                li { 'Source Tree access for home'}
                li { 'Use affiliations, allow smaller grouping for state branches etc'}
                li { 'Use date range for memberships'}
                li {  'Several Roles for a membership (different titles) new model, remove title from membership itself' }
                li {  'Search' }
                li { 'CRUD for People, Groups and Transfers'}
                li { 'Deploy' }
                li { 'Add Devise' }
                li { 'Add AdminUsers / Active Admin to edit all fields' }
                li { 'Node Linker - surface' }
                li { 'Make memberships for groups' }
                li { 'Several Memberships one person in one group'}
                li { 'New Server'}
                li { 'Domain name'}
                li { 'Auto Deployment' }
                li { 'Javascript' }
                li { 'jQuery' }
                li { 'Import Maps' }
                li { 'Add $$ totals on group and person page, by year' }
              end
            end
          end
        end
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'Doing' }
              ul do

                li { 'use size instead of count' }
                li { 'investigate ransack for filtering' }
                li { 'make some groups non-following' }
                li { 'Documentation / Content' }
                li { 'Images for About' }
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
                li { 'More Data from the AEC. Referendum data' }
                li { 'More Data from Fed Gov Expenditure: https://www.tenders.gov.au/senateorder/list' }
                li { 'Move search alinker forms to Phlex' }

                li { 'Theme / Color Scheme' }
                li { 'Bootstrap as an asset' }
                li { 'D3 JS' }
                li { 'Shortest Path between any two nodes (include_looser_nodes)' }

                li { 'Tests' }
                li { 'Get ASX data programatically' }


                li { 'Pagination' }
                li { 'More tests for record transfer taker' }


                li { 'Import Phlex JS' }
                li { 'Import People / Groups / Positions from CSV' }
                li { 'Add Indexes' }
                li { 'Add Audit table' }
                li { 'Ex Members of a group should appear last (app/views/components/groups/people.rb:3)' }
              end
            end
          end
        end
      end
    end
  end
end

# https://www.theguardian.com/commentisfree/2016/mar/01/larissa-waters-ban-donations-from-mining-companies-and-stop-ministers-working-for-them

# https://www.parliament.nsw.gov.au/members/downloadables/Pages/downloadable-lists.aspx
#

# https://www.echo.net.au/2015/02/former-pollies-staffers-mine-rich-vein-new-jobs/
# start again from here:
# Minerals Council of Australia staff...


# https://thenightly.com.au/opinion/political/cameron-milner-albanese-governments-future-made-in-australia-fund-has-been-lucrative-for-a-select-few-c-16466931