ActiveAdmin.register LeadershipWebsite do

  permit_params :group_id, :url, :people_card_selector, :name_selector, :title_selector, :reviewed_at

  filter :id
  filter :group
  filter :url
  filter :created_at

  index do
    selectable_column
    id_column
    column :group
    column :url do |lw|
      link_to lw.url, lw.url, target: '_blank' if lw.url.present?
    end
    column :people_card_selector
    column :name_selector
    column :title_selector
    column :reviewed_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :group
      row :url do |lw|
        link_to lw.url, lw.url, target: '_blank' if lw.url.present?
      end
      row :people_card_selector
      row :name_selector
      row :title_selector
      row :created_at
      row :updated_at
      row :reviewed_at
    end
  end

    # Add a "Merge With" button on the show page
    action_item :preview, only: :show do
      link_to 'Preview', preview_admin_leadership_website_path(resource), method: :get
    end

    # Custom route#action for the initial view of merging
    member_action :preview, method: :get do
      @current_leadership_website = resource
      @url = @current_leadership_website.url
      @people_card_selector = @current_leadership_website.people_card_selector
      @name_selector = @current_leadership_website.name_selector
      @title_selector = @current_leadership_website.title_selector
      page = Discovery::Website::PageDownloader.call(@url)
      # binding.pry
      @results = Discovery::Website::PageParser.call(
        page:,
        people_card_selector:  @current_leadership_website.people_card_selector,
        name_selector: @current_leadership_website.name_selector,
        title_selector: @current_leadership_website.title_selector
      )

      @preview_success = @results.present?

      render 'admin/leadership_websites/preview' # view for this action
    end


  # Custom route#action for the action of merging - we have the two groups now for the merge
    # member_action :perform_merge, method: :post do
    #   source_group = Group.find(params[:current_group_id])
    #   replacement_group = Group.find(params[:merge_with_group_id])
    #   replacement_group_name = replacement_group.name

    #   source_group.merge!(replacement_group)
    #   redirect_to admin_group_path(source_group), notice: "Group successfully merged with #{replacement_group_name}."
    # end

    member_action :record_people, method: :post do
      raise unless resource.present? && resource.reviewed_at.present?
      @current_leadership_website = resource
      group = @current_leadership_website.group
      @url = @current_leadership_website.url
      @people_card_selector = @current_leadership_website.people_card_selector
      @name_selector = @current_leadership_website.name_selector
      @title_selector = @current_leadership_website.title_selector
      page = Discovery::Website::PageDownloader.call(@url)
      # binding.pry
      people = Discovery::Website::PageParser.call(
        page:,
        people_card_selector:  @current_leadership_website.people_card_selector,
        name_selector: @current_leadership_website.name_selector,
        title_selector: @current_leadership_website.title_selector
      )
      # redirect_to admin_leadership_website_path(resource), notice: "People recording is not yet implemented."
# binding.pry
      people.each do |person_data|
        name = person_data[:name]
        title = person_data[:title]

        person = RecordPerson.call(name)
        membership = Membership.find_or_create_by(group:, member: person)
        Position.find_or_create_by(membership:, title:)
      end


      redirect_to admin_memberships_path, notice: "People have been recorded to the group #{resource.group.name}."
    end

  form do |f|
    if @results.present?
      panel "Preview Section" do
        para "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
      end
    end

    f.inputs do
      f.input :group_id, as: :string, label: 'Group ID'
      f.input :url, as: :string
      f.input :people_card_selector, as: :string, hint: 'CSS selector for people cards container'
      f.input :name_selector, as: :string, hint: 'CSS selector for name element'
      f.input :title_selector, as: :string, hint: 'CSS selector for title element'
      f.input :reviewed_at, as: :datepicker
    end

    f.actions do
      f.action :submit, label: 'Save Leadership Website'
      f.action :cancel
    end
  end





end
# .cmp-custom-columns__container
# .cmp-custom-columns__container