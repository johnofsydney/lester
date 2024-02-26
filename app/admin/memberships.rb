ActiveAdmin.register Membership do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :person_id, :group_id, :start_date, :end_date
  #
  # or
  #
  # permit_params do
  #   permitted = [:person_id, :group_id, :start_date, :end_date]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  permit_params :person_id, :group_id, :start_date, :end_date


  index do
    selectable_column
    id_column
    column(:person, sortable: 'person_id')
    column(:group, sortable: 'group_id')
    column :start_date
    column :end_date
  end
end
