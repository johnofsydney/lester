ActiveAdmin.register Membership do
  filter :group_name, as: :string, filters: %i[cont eq start end not_eq]

  permit_params :member_id, :group_id, :start_date, :end_date

  controller do
    def custom_action
      if params[:bulk_text].present?
        csv = CSV.parse(params[:bulk_text], headers: true)
        FileIngestor.general_upload(csv)

        flash[:notice] = "You submitted: #{params[:bulk_text]}"
        redirect_to admin_memberships_path
      else
        flash[:alert] = "Input cannot be blank."
        redirect_to admin_memberships_path
      end
    end
  end

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

  action_item :bulk_action_form, only: :index do
    link_to "Open Form", bulk_add_memberships_admin_memberships_path
  end

  collection_action :bulk_add_memberships, method: :get do
    raise unless current_admin_user
    render partial: "admin/memberships/bulk_add_memberships"
  end
end
