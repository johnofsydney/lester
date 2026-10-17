class Exports::FlattenedDataset
  PEOPLE_KEY = 'data-export/people.json'.freeze
  GROUPS_KEY = 'data-export/groups.json'.freeze

  def self.call
    new.call
  end

  def call
    Exports::S3Client.upload(PEOPLE_KEY, people_json)
    Exports::S3Client.upload(GROUPS_KEY, groups_json)
  end

  private

  def people_json
    Person.find_each.map { |person| node_row(person) }.to_json
  end

  def groups_json
    Group.find_each.map { |group| node_row(group) }.to_json
  end

  def node_row(node)
    summary = node.cached_summary || {}
    {
      id: node.id,
      type: node.class.name,
      name: node.name,
      is_tag: node.is_tag?,
      money_in: summary['money_in'],
      money_out: summary['money_out'],
      top_six_as_giver: summary['top_six_as_giver'],
      top_six_as_taker: summary['top_six_as_taker'],
      direct_connections: summary['direct_connections'],
      data_time_range: summary['data_time_range']
    }
  end
end
