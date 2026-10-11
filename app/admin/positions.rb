ActiveAdmin.register Position do
  filter :membership_group_name, as: :string, filters: %i[cont eq start end not_eq]
  filter :title

  permit_params :membership_id, :title, :start_date, :end_date, :evidence

  index do
    selectable_column
    id_column
    column('Member', sortable: 'member_id') { |position| position.membership.member.name }
    column('Group', sortable: 'group_id') { |position| position.membership.group.name }
    column(:title)
    column(:start_date)
    column(:end_date)
    actions
  end

  show do
    attributes_table do
      row :id
      row :membership do |position|
        link_to "Membership ##{position.membership_id}", admin_membership_path(position.membership_id)
      end
      row('Member') { |position| position.membership.member.name }
      row('Group') { |position| position.membership.group.name }
      row :title
      row :start_date
      row :end_date
      row :evidence
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs 'Position Details' do
      f.input :title
      f.input :start_date, as: :date_picker
      f.input :end_date, as: :date_picker
      f.input :evidence
    end
    f.actions
  end
end
