class Groups::AffiliatedGroups < ApplicationView

  attr_reader :group
	def initialize(group:)
		@group = group
	end

  def template
    turbo_frame(id: 'affiliated_groups') do

      affiliated_groups = group.affiliated_groups.reject{|group| group.category? }
      parent_categories = group.affiliated_groups.select{|group| group.category? }

      if parent_categories.present?
        render Groups::IndexView.new(
          groups: parent_categories,
          page: 0,
          pages: 1,
          subheading: 'Categories'
        )
      end

      if affiliated_groups.present?
        render Groups::IndexView.new(
          groups: affiliated_groups,
          page: 0,
          pages: 1,
          subheading: 'Affiliated Groups'
        )
      end
    end
  end
end
