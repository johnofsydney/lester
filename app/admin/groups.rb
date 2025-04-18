ActiveAdmin.register Group do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :name
  #
  # or
  #
  # permit_params do
  #   permitted = [:name]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  permit_params :name

  filter :id
  filter :name

  index do
    selectable_column
    id_column
    column(:name, sortable: 'name')
    column('Memberships (as owning group)') do |group|
      group.memberships.count
    end
    column('Transfers In') do |group|
      number_to_currency group.incoming_transfers.sum(:amount), precision: 0
    end
  end

  action_item :view_group, only: :show do
    link_to 'View Group', group_path(resource), method: :get
  end

  # Add a "Merge Into" button on the show page
  action_item :merge_into, only: :show do
    link_to 'Merge Into', merge_into_admin_group_path(resource), method: :get
  end

  # Custom page for selecting a group to merge into
  member_action :merge_into, method: :get do
    @current_group = resource
    render 'admin/groups/merge_into'
  end

  # Handle the merge logic
  member_action :perform_merge, method: :post do
    replacement_group = Group.find(params[:merge_into_group_id])
    source_group = Group.find(params[:current_group_id])

    source_group.merge_into(replacement_group)
    redirect_to admin_group_path(replacement_group), notice: "Group successfully merged into #{replacement_group.name}."
  end


  batch_action :add_to_category, form: -> {
    {
      category_id: Group.other_categories.map { |c| [c.name, c.id] }
    }
  } do |ids, inputs|
    category = Group.find(inputs[:category_id])
    Group.where(id: ids).find_each do |group|
      Membership.create(
        group: category,
        member: group,
        member_type: 'Group'
      )
    end

    redirect_to collection_path, alert: "Groups added to #{category.name}."
  end
end
