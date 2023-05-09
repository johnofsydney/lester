class Groups::ShowView < Phlex::HTML

  attr_reader :group

	def initialize(group:)
		@group = group
	end

	def template
    div(class: 'col-md-4') do
      div(class: 'card') do
        div(class: 'card-body') do
          a(href: "/groups/#{group.id}", class: 'btn w-100', style: "#{background_color(group)}; color: #{color(group)}") { group.name }
        end

        group.people.each do |person|
          div(class: 'list-group-item flex-normal') do
            div do
              a(href: "/people/#{person.id}", class: 'btn-primary btn', style: background_color(person)) { person.name }
            end
            div do
              person.groups.each do |group|
                a(href: "/groups/#{group.id}", class: 'btn-secondary btn btn-sml', style: "#{background_color(group)}; color: #{color(group)}" ) { group.name }
              end
            end
          end
        end
      end
    end

    a(href: '/group/new') { 'New Group' }
    a(href: "/group/#{group.id}/edit") { 'Edit Group' }
    a(href: '/people/') { 'People' }
	end

  def background_color(group)
    "background-color: \##{Digest::MD5.hexdigest(group.name)[0..5]};"
  end

  def invert_color(color)
    color.gsub!(/^#/, '')
    sprintf("%X", color.hex ^ 0xFFFFFF)
  end

  def color(group)
    color = Digest::MD5.hexdigest(group.name)[0..5]
    if color.hex > 0x7FFFFF
      'black'
    else
      'white'
    end
  end
end