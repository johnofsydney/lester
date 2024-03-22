ActiveAdmin.register Position do
  filter :membership_group_name, as: :string, filters: %i[cont eq start end not_eq]

  permit_params :membership_id, :title, :start_date, :end_date


  index do
    selectable_column
    id_column
    column('Member', sortable: 'member_id') { |position| position.membership.member.name }
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
