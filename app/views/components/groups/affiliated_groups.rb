class Groups::AffiliatedGroups < ApplicationView

  attr_reader :group
	def initialize(group:)
		@group = group
	end

  def template
    turbo_frame(id: 'affiliated_groups') do

  # TODO - make more DRY

      affiliated_groups = group.affiliated_groups
      parent_categories = affiliated_groups.select{|group| group.category? }

      if affiliated_groups.present?
        count = affiliated_groups.count

        if parent_categories.present?

          hr
          h4 { 'Categories' }

          if count < 4
            ul(class: 'list-group list-group-horizontal', style: 'flex-wrap: wrap;') do
              parent_categories.each do |category|
                li(class: 'list-group-item horizontal-button') do
                  evidence = Membership.find_by(group_id: group.id, member: category)&.evidence

                  span {a(href: "/groups/#{category.id}") { category.name }}
                  span {a(href: evidence, target: '_blank') { ' ...' }} if evidence.present?
                end
              end
            end
          else
            chunk_size = count / 3

            div(class: 'row') do
              parent_categories.sort_by(&:name).each_slice(chunk_size).to_a.each do |chunk|
                ul(class: 'col-md-4') do
                  chunk.each do |category|
                    li(class: 'list-group-item') do
                      evidence = Membership.find_by(group_id: group.id, member: category)&.evidence

                      span {a(href: "/groups/#{category.id}") { category.name }}
                      span {a(href: evidence, target: '_blank') { ' ...' }} if evidence.present?
                    end
                  end
                end
              end
            end
          end
        end

        hr
        h4 { 'Affiliated Groups' }

        if count < 4
          ul(class: 'list-group list-group-horizontal', style: 'flex-wrap: wrap;') do
            affiliated_groups.reject{|group| group.category? }.each do |affiliate|
              li(class: 'list-group-item horizontal-button') do
                evidence = Membership.find_by(group_id: group.id, member: affiliate)&.evidence

                span {a(href: "/groups/#{affiliate.id}", data_turbo: "false") { affiliate.name }}
                span {a(href: evidence, target: '_blank') { ' ...' }} if evidence.present?
              end
            end
          end
        else
          chunk_size = count # / 3

          div(class: 'row') do
            affiliated_groups.reject{|group| group.category? }.sort_by(&:name).each_slice(chunk_size).to_a.each do |chunk|
              ul(class: 'col') do
                chunk.each do |affiliate|
                  li(class: 'list-group-item') do
                    evidence = Membership.find_by(group_id: group.id, member: affiliate)&.evidence

                    span {a(href: "/groups/#{affiliate.id}", data_turbo: "false") { affiliate.name }}
                    span {a(href: evidence, target: '_blank') { ' ...' }} if evidence.present?
                  end
                end
              end
            end
          end
        end
      else
        # h1 { 'No affiliated groups' }
      end


    end
  end
end