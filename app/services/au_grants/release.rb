# Maps a parsed XLSX row hash into a nice Ruby object

class AuGrants::Release
  def initialize(row)
    @row = row
  end

  attr_reader :row

  def ga_id
    row['GA ID']
  end

  def agency_name
    row['Agency']
  end

  def recipient_name
    row['Recipient Name']
  end

  def recipient_abn
    abn = row['Recipient ABN']
    return nil if abn.blank? || abn == 'ABN Exempt'

    abn
  end

  def amount
    row['Value (AUD)'].to_f
  end

  def effective_date
    row['Publish Date'].to_date
  end

  def category
    row['Category']
  end

  def aggregate?
    row['Aggregate'] == 'Y'
  end

  def confidential?
    row['Confidentiality - Contract'] == 'Y'
  end

  def evidence
    "https://www.grants.gov.au/Ga/Show/#{ga_id}"
  end
end
