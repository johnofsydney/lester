ActiveAdmin.register Position do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :membership_id, :start_date, :end_date, :title
  #
  # or
  #
  # permit_params do
  #   permitted = [:membership_id, :start_date, :end_date, :title]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  filter :membership_person_name, as: :string, filters: %i[cont eq start end not_eq]
  filter :membership_group_name, as: :string, filters: %i[cont eq start end not_eq]

  permit_params :membership_id, :title, :start_date, :end_date


  index do
    selectable_column
    id_column
    column('Person', sortable: 'person_id') { |position| position.membership.person.name }
    column('Group', sortable: 'group_id') { |position| position.membership.group.name }
    column(:title)
    column(:start_date)
    column(:end_date)
  end

  form do |f|
    f.inputs 'Position Details' do
      f.input :title
      f.input :start_date, as: :date_picker
      f.input :end_date, as: :date_picker
    end
    f.actions
  end
end
