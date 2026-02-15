require 'nokogiri'
require 'open-uri'

class LinkedInProfileGetter
  attr_reader :person

  def initialize(person)
    @person = person
  end

  def perform
    conn = Faraday.new(
      url: 'https://nubela.co',
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{Rails.application.credentials.dig(:proxycurl, :api_key)}"
      }
    )

    response = conn.get('/proxycurl/api/v2/linkedin') do |req|
      req.params['linkedin_profile_url'] = person.linkedin_url
    end

    return unless response.success?

    previous_last_position = Position.order(id: :desc).last

    experiences = JSON.parse(response.body)['experiences']
    experiences.each do |experience|
      handle_experience(experience)
    end

    person.update!(linkedin_ingested: Time.zone.today)
    return true unless previous_last_position

    new_positions = Position.where(id: (previous_last_position.id + 1)...)
    new_positions.each do |position|
      handle_membership_dates(position)
    end

    true
  end

  def handle_membership_dates(position)
    membership = position.membership
    return unless membership
    return if Group.all_named_parties.include?(membership.group.name)

    membership.start_date = position.start_date if use_position_start_date?(position)
    membership.end_date = position.end_date if use_position_end_date?(position)
    membership.save!
  end

  def use_position_start_date?(position)
    membership = position.membership

    return false if position.start_date.blank?
    return true if membership.start_date.nil?

    membership.start_date > position.start_date
  end

  def use_position_end_date?(position)
    membership = position.membership

    return false if position.end_date.blank?
    return true if membership.end_date.nil?

    membership.end_date < position.end_date
  end

  def handle_experience(experience)
    # Process each experience item here
    Rails.logger.debug { "Company: #{experience['company']}" }
    Rails.logger.debug { "Title: #{experience['title']}" }
    Rails.logger.debug { "Location: #{experience['location']}" }
    Rails.logger.debug { "Description: #{experience['description']}" }
    Rails.logger.debug { "Logo URL: #{experience['logo_url']}" }
    Rails.logger.debug '-' * 40

    group = RecordGroup.call(experience['company'])
    # person
    title = if experience['title'].present?
      CapitalizeNames.capitalize(experience['title'].strip)
                     .gsub(/\bCEO\b/i) { |word| word.upcase }
    end

    evidence = person.linkedin_url
    start_date = parse_date(experience['starts_at']) if experience['starts_at'].present?
    end_date = parse_date(experience['ends_at']) if experience['ends_at'].present?

    # the membership may not exist, if so, we need to create it
    # There is no start date or end date added to the membership at this point
    membership = Membership.find_or_create_by(
      member_type: 'Person',
      member_id: person.id,
      group: group
    )
    # create position for each row, with unique dates and title
    if (title || start_date || end_date)
      position = Position.find_or_create_by(membership:, title:, start_date:, end_date:)
    end

    membership.update!(evidence:) if evidence
    position.update!(evidence:) if evidence && position
  end

  def parse_date(date_hash)
    return nil if date_hash.blank?

    begin
      Date.new(date_hash['year'], date_hash['month'], date_hash['day'])
    rescue => exception
      nil
    end
  end
end

# rubocop:disable Layout/LineLength
# body = JSON.parse(response.body)
# [11] pry(#<LinkedInProfileParser>)> body['experiences']
# => [{"starts_at"=>{"day"=>1, "month"=>7, "year"=>2022},
#   "ends_at"=>nil,
#   "company"=>"Sherpa Delivery",
#   "company_linkedin_profile_url"=>"https://www.linkedin.com/company/sherpa-pty-ltd/",
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Senior Software Engineer",
#   "description"=>nil,
#   "location"=>"Sydney, New South Wales, Australia",
#   "logo_url"=>
#    "https://s3.us-west-000.backblazeb2.com/proxycurl/company/sherpa-pty-ltd/profile?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=0004d7f56a0400b0000000001%2F20250402%2Fus-west-000%2Fs3%2Faws4_request&X-Amz-Date=20250402T043528Z&X-Amz-Expires=1800&X-Amz-SignedHeaders=host&X-Amz-Signature=b8e5d8b8afd2c6abf68557a2c75fd826ba9dce1af25a0159d1afa495c83011e6"},
#  {"starts_at"=>{"day"=>1, "month"=>8, "year"=>2021},
#   "ends_at"=>{"day"=>1, "month"=>7, "year"=>2022},
#   "company"=>"Mable",
#   "company_linkedin_profile_url"=>"https://www.linkedin.com/company/mableaustralia/",
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Software Engineer",
#   "description"=>"Ruby on Rails Engineer",
#   "location"=>"Sydney, New South Wales, Australia",
#   "logo_url"=>
#    "https://s3.us-west-000.backblazeb2.com/proxycurl/company/mableaustralia/profile?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=0004d7f56a0400b0000000001%2F20250402%2Fus-west-000%2Fs3%2Faws4_request&X-Amz-Date=20250402T043528Z&X-Amz-Expires=1800&X-Amz-SignedHeaders=host&X-Amz-Signature=4202d231954d2be2750d1976b5a32eadb3744a382f535ba7c061feb286d0c583"},
#  {"starts_at"=>{"day"=>1, "month"=>12, "year"=>2018},
#   "ends_at"=>{"day"=>1, "month"=>7, "year"=>2021},
#   "company"=>"Fat Zebra",
#   "company_linkedin_profile_url"=>"https://www.linkedin.com/company/fat-zebra/",
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Software Developer",
#   "description"=>"- Ruby, Rails, RSpec, TDD\n- Postgresql, SQL\n- Sidekiq, Redis\n- AWS - Dynamo DB, Lambdas, SQS, S3\n- CI/CD (Buildkite)\n- Git, bash / zsh",
#   "location"=>"Sydney, Australia",
#   "logo_url"=>
#    "https://s3.us-west-000.backblazeb2.com/proxycurl/company/fat-zebra/profile?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=0004d7f56a0400b0000000001%2F20250402%2Fus-west-000%2Fs3%2Faws4_request&X-Amz-Date=20250402T043528Z&X-Amz-Expires=1800&X-Amz-SignedHeaders=host&X-Amz-Signature=117cf005aac0b13e7a0cab60cdf050211cb33b58d4e074e43606315220104b7f"},
#  {"starts_at"=>{"day"=>1, "month"=>9, "year"=>2018},
#   "ends_at"=>{"day"=>1, "month"=>11, "year"=>2018},
#   "company"=>"SBS",
#   "company_linkedin_profile_url"=>"https://www.linkedin.com/company/sbs/",
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Software Developer",
#   "description"=>nil,
#   "location"=>"Sydney, Australia",
#   "logo_url"=>
#    "https://s3.us-west-000.backblazeb2.com/proxycurl/company/sbs/profile?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=0004d7f56a0400b0000000001%2F20250402%2Fus-west-000%2Fs3%2Faws4_request&X-Amz-Date=20250402T043528Z&X-Amz-Expires=1800&X-Amz-SignedHeaders=host&X-Amz-Signature=6332de9be9a0a59976765541539cf0ae405d836130c21da532228563df122205"},
#  {"starts_at"=>{"day"=>1, "month"=>2, "year"=>2018},
#   "ends_at"=>{"day"=>1, "month"=>9, "year"=>2018},
#   "company"=>"General Assembly",
#   "company_linkedin_profile_url"=>"https://www.linkedin.com/school/generalassembly/",
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Teaching Assistant",
#   "description"=>"Teaching Assistant for full-stack Web Development Immersive course at GA. Covering HTML, CSS, Javascript, Ruby on Rails and more...",
#   "location"=>"Sydney, Australia",
#   "logo_url"=>"https://media.licdn.com/dms/image/C4E0BAQEwAxD22k-HBw/company-logo_400_400/0/1629948625988?e=1694044800&v=beta&t=VLhN5SmVSV8aosdXlYtMdHhkgWePBqBR2YbzXc-IK8c"},
#  {"starts_at"=>{"day"=>1, "month"=>10, "year"=>2017},
#   "ends_at"=>{"day"=>1, "month"=>1, "year"=>2018},
#   "company"=>"General Assembly",
#   "company_linkedin_profile_url"=>"https://www.linkedin.com/school/generalassembly/",
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Web Development Immersive Student",
#   "description"=>
#    "A 12 week full time course covering;\n* HTML\n* CSS, including libraries such as Bootstrap, Animations etc\n* Javascript, including libraries such  as JQuery, underscore and Three.JS\n* Use of APIs, such as google geoCharts etc\n* Ruby on Rails, with Sinatra and Postgresql databases\n* Ruby gems such as Cloudinary and Nokogiri\n* React\n* git / GitHub / collaborating on a project using git\n* deployment to GitHub pages and Heroku\n\n\nMy Projects at GA can be seen in more detail at https://johnofsydney.github.io/ and included:\n\nElemental\n\nThe website stores and displays data of elements in the periodic table, the scientists that discovered or described these elements, and the countries where the major deposits may be found\n\n* Built in Ruby on Rails\n* Models, Views, Controllers (MVC) application.\n* Image upload using Cloudinary\n* Webscraping using NokoGiri\n* Javascript libraries: Three.JS, underscore, particle.js and jQuery\n* Google geoCharts and bar charts\n* Bootstrap CSS, CSS Grid\n* Maths to animate the spinning Three.JS electrons\n\n\n\nFM_Booker\n\nThe application concept is an uber for facilities management companies and service technicians. A booker will create a job, and a technician can select the jobs they want to undertake.\n\n* Built in Ruby on Rails\n* Models, Views, Controllers (MVC) application.\n* User Login function\n* Search using pgSearch\n* Image upload using Cloudinary\n* Google Maps\n* Bootstrap CSS\n\n\nTic Tac Toe / Connect 4 / Othello\n\nOur first solo project, everyone has to make Tic Tac Toe. Instead of working on a one player vs the computer game I concentrated on building in more games and doing my best to re-use as much common game logic as I could.\n\nMy site allows you to play Tic Tac Toe or Connect 4 or Othello / Reversi, the actual game is selected according to the size of the game board chosen by the user.\n\n* HTML\n* CSS\n* Javascript, JQuery",
#   "location"=>"Sydney, Australia",
#   "logo_url"=>"https://media.licdn.com/dms/image/C4E0BAQEwAxD22k-HBw/company-logo_400_400/0/1629948625988?e=1694044800&v=beta&t=VLhN5SmVSV8aosdXlYtMdHhkgWePBqBR2YbzXc-IK8c"},
#  {"starts_at"=>{"day"=>1, "month"=>9, "year"=>2006},
#   "ends_at"=>{"day"=>1, "month"=>9, "year"=>2017},
#   "company"=>"DataHouseSoftware",
#   "company_linkedin_profile_url"=>nil,
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Software Development",
#   "description"=>
#    "\"Pipeline\" was the MS Access application I developed to run my own recruitment business, and also licensed to several other small recruitment consultancies.\n- tracking of candidates and sales contacts\n- integration with MS Outlook for email and calendar functions\n- integration with 3rd party applications for SMS and VOIP calling\n- Forms, Queries, Reports, Tables, VBA - all the MS Access components\n- connection to local mdb file or SQL Server database\n- website design\n- create features from customer's enquiries\n\nSome testimonials:\n\"Pipeline is the most user friendly, intuitive system I have found in the 12 years I have been in recruitment.\"\n\"The back end service we have received from DataHouseSoftware has been exceptional.\"\n\"We evaluated 21 different software packages to keep our business running efficiently, Datahouse beat them all.\"\n\"I have found Pipeline to be excellent, it is totally practical, user friendly and is a no-nonsense database, which allows me to do my job more efficiently\"",
#   "location"=>nil,
#   "logo_url"=>nil},
#  {"starts_at"=>{"day"=>1, "month"=>9, "year"=>2006},
#   "ends_at"=>{"day"=>1, "month"=>3, "year"=>2014},
#   "company"=>"Stafford Island",
#   "company_linkedin_profile_url"=>nil,
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Recruitment Consultant",
#   "description"=>"Recruitment of Engineers and related technical people for companies in Sydney, NSW and throughout Australia.",
#   "location"=>nil,
#   "logo_url"=>nil},
#  {"starts_at"=>{"day"=>1, "month"=>3, "year"=>2000},
#   "ends_at"=>{"day"=>1, "month"=>9, "year"=>2017},
#   "company"=>"Hawker Batteries, Com10 International, Emerson Network Power",
#   "company_linkedin_profile_url"=>nil,
#   "company_facebook_profile_url"=>nil,
#   "title"=>"Electrical Design Engineer",
#   "description"=>
#    "Electrical Engineer for various companies, principally the manufacturing of Electronic Power Conversion equipment for the Telecommunications Industry.\n\nCAD Design, Project Management, Engineering Calculations",
#   "location"=>"Sydney, Australia",
#   "logo_url"=>nil}]
# rubocop:enable Layout/LineLength