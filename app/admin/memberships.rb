ActiveAdmin.register Membership do
  filter :group_name, as: :string, filters: %i[cont eq start end not_eq]

  permit_params :member_id, :group_id, :start_date, :end_date

  controller do
    def general_upload_action
      if params[:bulk_text].present?
        csv = CSV.parse(params[:bulk_text], headers: true)
        FileIngestor.general_upload(csv)

        flash[:notice] = "Success!"
        redirect_to admin_memberships_path
      else
        flash[:alert] = "Input cannot be blank."
        redirect_to admin_memberships_path
      end
    end

    def ministries_upload_action
      if params[:bulk_text].present?
        csv = CSV.parse(params[:bulk_text], headers: true)
        FileIngestor.general_upload(csv)

        flash[:notice] = "Success!"
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

  action_item :general_upload_form, only: :index do
    link_to "General Upload Form", general_upload_form_admin_memberships_path
  end

  collection_action :general_upload_form, method: :get do
    raise unless current_admin_user
    render partial: "admin/memberships/general_upload_form"
  end

  action_item :ministries_upload_form, only: :index do
    link_to "Ministries Upload Form", ministries_upload_form_admin_memberships_path
  end

  collection_action :ministries_upload_form, method: :get do
    raise unless current_admin_user
    render partial: "admin/memberships/ministries_upload_form"
  end
end
