require 'capitalize_names'

class Abn::FetchBusinessNames
  def self.call(abn)
    new(abn).call
  end

  def initialize(abn)
    @abn = abn
  end

  def call
    response = connection.get(url)
    body = response.env.response_body
    business_entity_details = Hash.from_xml(body)['ABRPayloadSearchResults']['response']['businessEntity201205']
    raise "ABN not found" unless business_entity_details

    main_name = business_entity_details['mainName']['organisationName']
    main_trading_name = if business_entity_details['mainTradingName']
                          business_entity_details['mainTradingName']['organisationName']
                        else
                          nil
                        end

    other_names = [main_trading_name] + other_trading_names(business_entity_details) + other_business_names(business_entity_details)

    {
      abn: @abn,
      main_name: capitalize(main_name),
      trading_names: other_names.compact.map { |name| capitalize(name) }.uniq
    }
  end

  def other_trading_names(business_entity_details)
    other_trading_name = business_entity_details['otherTradingName']

    map_or_extract_from_hash(other_trading_name)
  end

  def other_business_names(business_entity_details)
    business_name = business_entity_details['businessName']

    map_or_extract_from_hash(business_name)
  end

  def map_or_extract_from_hash(detail)
    if detail.is_a?(Array)
      detail.map {|e| e['organisationName'] }
    elsif detail.is_a?(Hash)
      [detail['organisationName']]
    else
      []
    end
  end

  def capitalize(str)
    CapitalizeNames.capitalize(str.strip)
  end

  def authentication_guid
    Rails.application.credentials.abn_lookup[:authentication_guid]
  end

  def url
    host = 'https://abr.business.gov.au'
    endpoint = '/AbrXmlSearch/AbrXmlSearch.asmx/SearchByABNv201205'
    params = "?searchString=#{@abn}&includeHistoricalDetails=N&authenticationGuid=#{authentication_guid}"

    "#{host}#{endpoint}#{params}"
  end

  def connection
    conn = Faraday.new
  end
end


# eg Hash.from_xml(body) = {
# {
#   "ABRPayloadSearchResults"=> {
#     "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
#     "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
#     "xmlns"=>"http://abr.business.gov.au/ABRXMLSearch/",
#     "request"=>{"identifierSearchRequest"=>{"authenticationGUID"=>"XXXX", "identifierType"=>"ABN", "identifierValue"=>"19002966001", "history"=>"N"}},
#     "response"=>{
#       "usageStatement"=>"The Registrar of the ABR monitors the quality of the information available on this website and updates the information regularly. However, neither the Registrar of the ABR nor the Commonwealth guarantee that the information available through this service (including search results) is accurate, up to date, complete or accept any liability arising from the use of or reliance upon this site.",
#       "dateRegisterLastUpdated"=>"2026-01-07",
#       "dateTimeRetrieved"=>"2026-01-07T16:10:36.2943459+11:00",
#       "businessEntity201205"=> {
#         "recordLastUpdatedDate"=>"2025-04-03",
#         "ABN"=>{"identifierValue"=>"19002966001", "isCurrentIndicator"=>"Y", "replacedFrom"=>"0001-01-01"},
#         "entityStatus"=>{"entityStatusCode"=>"Active", "effectiveFrom"=>"2000-04-06", "effectiveTo"=>"0001-01-01"},
#         "ASICNumber"=>"002966001",
#         "entityType"=>{"entityTypeCode"=>"PRV", "entityDescription"=>"Australian Private Company"},
#         "goodsAndServicesTax"=>{"effectiveFrom"=>"2010-07-01", "effectiveTo"=>"0001-01-01"},
#         "mainName"=>{"organisationName"=>"MEDIABRANDS AUSTRALIA PTY LTD", "effectiveFrom"=>"2010-06-10"},
#         "mainTradingName"=>{"organisationName"=>"Airborne", "effectiveFrom"=>"2012-03-12"},
#         "otherTradingName"=> [
#           {"organisationName"=>"Ansible", "effectiveFrom"=>"2012-03-12"},
#           {"organisationName"=>"Ensemble Branded Entertainment", "effectiveFrom"=>"2012-03-12"},
#           {"organisationName"=>"Marketing Sciences Australia", "effectiveFrom"=>"2012-03-12"},
#           {"organisationName"=>"MBThree", "effectiveFrom"=>"2012-03-12"},
#           {"organisationName"=>"Media Brands Analysts", "effectiveFrom"=>"2012-03-12"},
#           {"organisationName"=>"Reprise Media", "effectiveFrom"=>"2012-03-12"},
#           {"organisationName"=>"Universal McCann", "effectiveFrom"=>"2012-03-12"}
#         ],
#         "mainBusinessPhysicalAddress"=>{"stateCode"=>"NSW", "postcode"=>"2010", "effectiveFrom"=>"2022-12-02", "effectiveTo"=>"0001-01-01"},
#         "businessName"=>[
#           {"organisationName"=>"OneEngine", "effectiveFrom"=>"2025-03-25"},
#           {"organisationName"=>"TEAM INSPIRE", "effectiveFrom"=>"2024-05-16"},
#           {"organisationName"=>"Mediabrands Content Studios", "effectiveFrom"=>"2022-01-13"},
#           {"organisationName"=>"Group Yellow", "effectiveFrom"=>"2021-08-03"},
#           {"organisationName"=>"Rapport Media", "effectiveFrom"=>"2017-01-30"},
#           {"organisationName"=>"Mediabrands Group", "effectiveFrom"=>"2014-09-25"},
#           {"organisationName"=>"Anomaly Research and Analytics", "effectiveFrom"=>"2013-10-17"},
#           {"organisationName"=>"Brand Programming Network", "effectiveFrom"=>"2013-03-15"},
#           {"organisationName"=>"MAGNAGLOBAL AUSTRALIA", "effectiveFrom"=>"2011-10-11"},
#           {"organisationName"=>"ENSEMBLE BRANDED ENTERTAINMENT", "effectiveFrom"=>"2010-06-17"},
#           {"organisationName"=>"REPRISE MEDIA", "effectiveFrom"=>"2009-04-24"},
#           {"organisationName"=>"UNIVERSAL MCCANN", "effectiveFrom"=>"2004-08-12"}
#         ]
#       }
#     }
#   }
# }
