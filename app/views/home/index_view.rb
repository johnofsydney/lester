class Home::IndexView < ApplicationView
  include Phlex::Rails::Helpers::TimeAgoInWords

  STATUS_LABELS = {
    'not-started' => 'Not started',
    'designed' => 'Designed',
    'investigating' => 'Investigating',
    'in-progress' => 'In progress',
    'waiting-on-verification' => 'Being verified',
    'blocked' => 'Paused',
    'complete' => 'Done'
  }.freeze

  DATA_SOURCE_GROUPS = [
    { label: 'AEC Annual Donor records since 1999', url: 'https://transparency.aec.gov.au/AnnualDonor', frequency: 'Manual trigger' },
    { label: 'AEC 2023 Referendum Donor Returns', url: 'https://transparency.aec.gov.au/ReferendumDonor', frequency: 'Manual trigger' },
    { label: 'AEC Election Donor Returns since 2007', url: 'https://transparency.aec.gov.au/Donor', frequency: 'Manual trigger' },
    { label: 'Federal Government Contracts since 2018', url: 'https://www.tenders.gov.au/cn/search', frequency: 'Daily',
      keys: %w[AusTender::IngestContractsDateJob AusTender::BackfillContractsMasterJob] },
    { label: 'Lobbyists and the Clients of Lobbyists', url: 'https://lobbyists.ag.gov.au/register', frequency: 'Twice yearly (Apr & Oct)',
      keys: %w[AuLobbyists::IngestLobbyistsJob] },
    { label: 'Charities and Not-For-Profit Organisations', url: 'https://www.acnc.gov.au/', frequency: 'Yearly',
      keys: %w[Acnc::IngestDatasetCsvJob Acnc::IngestMissingPeopleJob Acnc::IngestSingleCharityPeopleJob] },
    { label: 'Federal MPs and Senators', url: 'https://en.wikipedia.org/wiki/Category:Members_of_Australian_parliaments_by_term', frequency: 'Monthly',
      keys: %w[OpenAustralia::IngestCurrentPoliticiansJob OpenAustralia::IngestPersonJob] },
    { label: 'NSW council elections', frequency: 'Monthly',
      keys: %w[Councils::Nsw::IngestElectionResultsJob Councils::Nsw::IngestByElectionResultsJob
               Councils::Nsw::ImportCouncilResultRowJob Councils::Nsw::ImportByElectionResultRowJob] },
    { label: 'VIC council elections', frequency: 'Monthly',
      keys: %w[Councils::Vic::IngestElectionResultsJob Councils::Vic::IngestByElectionResultsJob
               Councils::Vic::ImportCouncilResultRowJob Councils::Vic::ImportByElectionResultRowJob] },
    { label: 'QLD council elections', frequency: 'Monthly',
      keys: %w[Councils::Qld::IngestElectionResultsJob Councils::Qld::ImportElectionResultsJob Councils::Qld::RecordContestResultJob] },
    { label: 'NSW state politicians', frequency: 'Ad hoc, as elections occur',
      keys: %w[NswStatePoliticians::IngestElectionResultsJob NswStatePoliticians::ImportLaElectorateResultJob] },
    { label: 'Various ad-hoc data sources added directly', frequency: 'Manual, as needed' }
  ].freeze

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
                    th { 'Update Frequency' }
                    th { 'Status' }
                    th { 'Last Run' }
                  end
                end
                tbody do
                  data_sources.each do |source|
                    tr do
                      td { source.url ? a(href: source.url) { source.label } : plain(source.label) }
                      td { plain source.frequency }
                      td { data_source_status_badge(source) }
                      td { source.last_run_at ? plain("#{time_ago_in_words(source.last_run_at)} ago") : plain('—') }
                    end
                  end
                end
              end
            end
          end
          div(class: 'card shadow-sm mb-4') do
            div(class: 'card-body') do
              p { 'We keep this project moving in the open. Here is an honest summary of the major initiatives currently underway and their status.' }

              table(class: 'table table-striped') do
                thead do
                  tr do
                    th { 'Initiative' }
                    th { 'Status' }
                    th { 'Summary' }
                  end
                end
                tbody do
                  major_initiatives.each do |initiative|
                    tr do
                      td { strong { initiative[:title] } }
                      td { span(class: "badge #{initiative_status_class(initiative[:status])}") { STATUS_LABELS.fetch(initiative[:status], initiative[:status]) } }
                      td { plain initiative[:summary].to_s.squish }
                    end
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

  private

  def data_sources
    @data_sources ||= DATA_SOURCE_GROUPS.map { |group| Home::DataSourceHealth.new(**group) }
  end

  def data_source_status_badge(source)
    case source.state
    when :ok then span(class: 'badge bg-success') { 'OK' }
    when :failing then span(class: 'badge bg-danger') { 'Failing' }
    when :manual then span(class: 'badge bg-secondary') { 'Manual' }
    when :unknown then span(class: 'badge bg-secondary') { 'Not yet run' }
    end
  end

  def major_initiatives
    @major_initiatives ||= YAML.load_file(Rails.root.join('app/views/home/major_initiatives.yml')).map(&:symbolize_keys)
  end

  def initiative_status_class(status)
    {
      'not-started' => 'bg-secondary',
      'designed' => 'bg-secondary',
      'investigating' => 'bg-info',
      'in-progress' => 'bg-primary',
      'waiting-on-verification' => 'bg-warning text-dark',
      'blocked' => 'bg-danger',
      'complete' => 'bg-success'
    }.fetch(status, 'bg-secondary')
  end
end
