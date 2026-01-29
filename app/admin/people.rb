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

  permit_params :name, :linkedin_url

  filter :id
  filter :name
  filter :name, as: :string, filters: %i[cont eq start end not_eq]
  filter :linkedin_url
  filter :linkedin_ingested, as: :date_range

  index do
    selectable_column
    id_column
    column(:name, sortable: 'person_id')
    column :linkedin_url
    column :linkedin_ingested
  end

  show do
    attributes_table do
      row :id
      row :name
      row :created_at
      row :updated_at
      row :linkedin_url
      row :linkedin_ingested
    end
  end

  form do |f|
    f.inputs 'Person' do
      f.input :name
      f.input :linkedin_url
    end
    f.actions
  end

  action_item :view_person, only: :show do
    link_to 'View Person', person_path(resource), method: :get
  end

  batch_action :ingest_linkedin_batch, confirm: 'Are you sure you want to ingest LinkedIn data for these people?' do |ids|
    ids.each do |id|
      LinkedinProfileGetterJob.perform_async(id)
    end

    redirect_to collection_path, alert: 'LinkedIn data ingested successfully.'
  end

  # Add a "Get Linked In" button on the show page
  action_item :ingest_linkedin, only: :show do
    link_to 'Ingest Linked In', ingest_linkedin_admin_person_path(resource), method: :post
  end

  # Handle the ingestion logic
  member_action :ingest_linkedin, method: :post do
    person = resource

    LinkedinProfileGetterJob.perform_async(person.id)
  end
end
