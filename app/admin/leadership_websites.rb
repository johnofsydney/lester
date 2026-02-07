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
      link_to lw.url, lw.url, target: '_blank', rel: 'noopener' if lw.url.present?
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
        link_to lw.url, lw.url, target: '_blank', rel: 'noopener' if lw.url.present?
      end
      row :people_card_selector
      row :name_selector
      row :title_selector
      row :created_at
      row :updated_at
      row :reviewed_at
    end
  end

  # Add a button on the show page
  action_item :preview, only: :show do
    link_to 'Preview', preview_admin_leadership_website_path(resource), method: :get
  end

  # Custom route#action for the preview view
  member_action :preview, method: :get do
    @current_leadership_website = resource

    page = Discovery::Website::PageDownloader.call(resource.url)

    if page.blank?
      redirect_to admin_leadership_website_path(resource), alert: 'Failed to download the page. Please check the URL and try again.'
      return
    end
    @results = Discovery::Website::PageParser.call(
      page:,
      people_card_selector: resource.people_card_selector,
      name_selector: resource.name_selector,
      title_selector: resource.title_selector
    )

    render 'admin/leadership_websites/preview' # view for this action
  end

  # custom route#action triggered from the preview page to record people to the group
  member_action :record_people, method: :post do
    raise if resource.blank?

    resource.update(reviewed_at: Time.current)

    page = Discovery::Website::PageDownloader.call(resource.url)

    people = Discovery::Website::PageParser.call(
      page:,
      people_card_selector: resource.people_card_selector,
      name_selector: resource.name_selector,
      title_selector: resource.title_selector
    )

    people.each do |person_data|
      person_name = person_data[:name]
      title = person_data[:title]

      Group::RecordRow.new(group: resource.group, person_name:, title:).call
    end

    redirect_to admin_memberships_path, notice: "People have been recorded to the group #{resource.group.name}."
  end

  form do |f|
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
