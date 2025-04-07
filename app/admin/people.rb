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
  filter :linkedin_url
  filter :linkedin_ingested, as: :date_range

  index do
    selectable_column
    id_column
    column(:name, sortable: 'person_id')
    column :linkedin_url
    column :linkedin_ingested
  end

  form do |f|
    f.inputs 'Person' do
      f.input :name
      f.input :linkedin_url
    end
    f.actions
  end

  batch_action :ingest_linkedin, confirm: 'Are you sure you want to ingest LinkedIn data for these people?' do |ids|
    ids.each do |id|
      person = Person.find(id)
      # Assuming you have a method to ingest LinkedIn data
      # person.ingest_linkedin_data
      LinkedInProfileGetter.new(person).perform
    end

    redirect_to collection_path, alert: 'LinkedIn data ingested successfully.'
  end
end
