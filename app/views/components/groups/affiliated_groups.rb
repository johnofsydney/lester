class Groups::AffiliatedGroups < ApplicationView

  attr_reader :group
	def initialize(group:)
		@group = group
	end

  def template

    if group.affiliated_groups.present?
      count = group.affiliated_groups.count

      hr
        h4 { 'Affiliated Groups' }

        if count < 4
          ul(class: 'list-group list-group-horizontal', style: 'flex-wrap: wrap;') do
            group.affiliated_groups.each do |affiliate|
              li(class: 'list-group-item horizontal-button') do
                evidence = Membership.find_by(group_id: group.id, member: affiliate)&.evidence

                span {a(href: "/groups/#{affiliate.id}") { affiliate.name }}
                span {a(href: evidence, target: '_blank') { ' ...' }} if evidence.present?
              end
            end
          end
        else
          chunk_size = count / 3

          div(class: 'row') do
            group.affiliated_groups.sort_by(&:name).each_slice(chunk_size).to_a.each do |chunk|
              ul(class: 'col-md-4') do
                chunk.each do |affiliate|
                  li(class: 'list-group-item') do
                    evidence = Membership.find_by(group_id: group.id, member: affiliate)&.evidence

                    span {a(href: "/groups/#{affiliate.id}") { affiliate.name }}
                    span {a(href: evidence, target: '_blank') { ' ...' }} if evidence.present?
                  end
                end
              end
            end
          end
        end
    end
  end
end