ActiveAdmin.register Person do

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
  filter :name, as: :string, filters: %i[cont eq start end not_eq]

  index do
    selectable_column
    id_column
    column(:name, sortable: 'person_id')
  end

  form do |f|
    f.inputs 'Person' do
      f.input :name
      f.input :linkedin_url
    end
    f.actions
  end
end
