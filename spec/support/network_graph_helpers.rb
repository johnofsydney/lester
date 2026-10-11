module NetworkGraphHelpers
  def page_prop(key)
    page_props = JSON.parse(response.body[/data-page="([^"]+)"/, 1].gsub('&quot;', '"'))['props']
    JSON.parse(page_props[key])
  end

  def cached_descendent(id:, name:, klass:, depth:)
    {
      'parent_id' => nil, 'parent_name' => nil, 'parent_klass' => nil, 'parent_count' => 0,
      'id' => id, 'name' => name, 'klass' => klass, 'depth' => depth,
      'shape' => 'dot', 'color' => 'rgba(0,0,0,1)', 'mass' => 2, 'size' => 5,
      'url' => "/#{klass.downcase.pluralize}/#{id}", 'last_position' => nil, 'is_tag' => false
    }
  end
end

RSpec.configure do |config|
  config.include NetworkGraphHelpers, type: :request
end
