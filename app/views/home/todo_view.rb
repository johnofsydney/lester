class Home::TodoView < ApplicationView
  def view_template
    div(class: 'container') do
      div(class: 'row', id: 'todo') do
        h2 { 'TODO:' }
        div(class: 'col-sm') do
          div(class: 'card') do
            div(class: 'card-body') do
              h5(class: 'card-title') { 'Doing' }
              ul do
                li { 're-import donations as Individual Transactions' }
                li { 'use size instead of count' }
                li { 'investigate ransack for filtering' }
                li { 'make some groups non-following' }
                li { 'make some memberships not-really eg Nova Systems is not really a lobbyist' }
                li { 'Use categories for individual transactions' }
                li { 'Use Tags where appropriate eg homepage' }
                li { 'Make a Parent Group type - lower level groups can belong to only one parent (maybe a new table?)' }
                li { 'remove group.category everywhere' }
                li { 'Images for About' }
                li { 'Write tests for Build Queue service and attend to TODOs' }

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

                li { 'Tests' }
                li { 'Get ASX data programatically' }

                li { 'Pagination' }
                li { 'More tests for record transfer taker' }

                li { 'Add Audit table' }
                li { 'Ex Members of a group should appear last (or not at all eg Lidia Thorpe) (app/views/components/groups/people.rb:3)' }
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

# https://www.parliament.act.gov.au/function/tru/act-register-of-lobbyists/act-register-of-lobbyists4/CMAX-Communications
# need an AKA for CMAX Communications / Advisory

# State based donations:
# https://efadisclosures.elections.nsw.gov.au/
# https://disclosures.vec.vic.gov.au/public-donations/
# https://helpcentre.disclosures.ecq.qld.gov.au/hc/en-us
# https://www.ecsa.sa.gov.au/parties-and-candidates/funding-and-disclosure-state-elections/public-inspection
# https://disclosures.elections.wa.gov.au/public-dashboard/
# https://ntec.nt.gov.au/financial-disclosure/published-annual-returns/2023-2024-annual-returns

# have emailed NSW and NT asking for better tabular data on 2025-4-14
