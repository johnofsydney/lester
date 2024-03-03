class ShortestPathResults < ApplicationView
  def initialize(shortest_path: nil)
    @shortest_path = shortest_path
  end

  attr_reader :shortest_path

  def template
    return if shortest_path.empty?
    div(class: 'card') do
      h3 { "#{shortest_path.first} => #{shortest_path.last}" }
      shortest_path.each do |piece|
        p { piece }
      end
    end
  end
end

  # id: 32,
  # content: "John Kirby",
  # searchable_type: "Person",
  # searchable_id: 32,
  # created_at: Thu, 22 Feb 2024 10:39:14.518121000 UTC +00:00,
  # updated_at: Thu, 22 Feb 2024 10:39:14.518121000 UTC +00:00>,