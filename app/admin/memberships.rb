ActiveAdmin.register Membership do
  # filter :member_name, as: :string, filters: %i[cont eq start end not_eq]
  filter :group_name, as: :string, filters: %i[cont eq start end not_eq]

  permit_params :member_id, :group_id, :start_date, :end_date

  index do
    selectable_column
    id_column
    column(:member, sortable: 'member_id')
    column(:group, sortable: 'group_id')
    column :start_date
    column :end_date
  end

  form do |f|
    f.inputs 'Membership Details' do
      f.input :start_date, as: :date_picker
      f.input :end_date, as: :date_picker
    end
    f.actions
  end
end
