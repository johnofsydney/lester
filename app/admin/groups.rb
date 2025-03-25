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
    column(:memberships) do |group|
      group.memberships.count
    end
    column('Transfers In') do |group|
      number_to_currency group.incoming_transfers.sum(:amount), precision: 0
    end
  end

  batch_action :add_to_category, form: -> {
    {
      category_id: Group.other_categories.map { |c| [c.name, c.id] }
    }
  } do |ids, inputs|
    category = Group.find(inputs[:category_id])
    Group.where(id: ids).each do |group|
      Membership.create(
        group: category,
        member: group,
        member_type: 'Group'
      )
    end

    redirect_to collection_path, alert: "Groups added to #{category.name}."
  end
end
