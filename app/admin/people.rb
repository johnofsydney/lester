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
  filter :views, as: :numeric
  filter :linkedin_url
  filter :linkedin_ingested, as: :date_range

  index do
    selectable_column
    id_column
    column(:name, sortable: 'person_id')
    column :views
    column :linkedin_url
    column :linkedin_ingested
  end

  show do
    attributes_table do
      row :id
      row :name
      row :created_at
      row :updated_at
      row :attributed_to
      row :linkedin_url
      row :linkedin_ingested
      row :views
    end

    panel 'Memberships (as member group)' do
      table_for Membership.where(member: resource).order(created_at: :desc) do
        column :id do |membership|
          link_to membership.id, admin_membership_path(membership)
        end
        column :group
        column :position
        column :start_date
        column :end_date
        column :created_at
      end
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

  # batch_action :ingest_linkedin_batch, confirm: 'Are you sure you want to ingest LinkedIn data for these people?' do |ids|
  #   ids.each do |id|
  #     Linkedin::ProfileGetterJob.perform_async(id)
  #   end

  #   redirect_to collection_path, alert: 'LinkedIn data ingested successfully.'
  # end

  # # Add a "Get Linked In" button on the show page
  # action_item :ingest_linkedin, only: :show do
  #   link_to 'Ingest Linked In', ingest_linkedin_admin_person_path(resource), method: :post
  # end

  # # Handle the ingestion logic
  # member_action :ingest_linkedin, method: :post do
  #   person = resource

  #   Linkedin::ProfileGetterJob.perform_async(person.id)
  # end

  action_item :explode_person, only: :show do
    link_to 'Explode Person', explode_person_admin_person_path(resource), method: :get
  end

  # Handle the explosion logic
  member_action :explode_person, method: :get do
    membership_ids = Admin::People::ExplodePerson.call(resource)

    if membership_ids.any?
      redirect_to admin_memberships_path(q: { by_ids: membership_ids.join(',') }), notice: 'Person exploded.'
    else
      redirect_to admin_memberships_path, alert: 'No memberships were found for this person.'
    end
  end

  # Add a "Merge With" button on the show page
  action_item :merge_with, only: :show do
    link_to 'Merge With', merge_with_admin_person_path(resource), method: :get
  end

  # Custom route#action for the initial view of merging
  member_action :merge_with, method: :get do
    @current_person = resource
    render 'admin/people/merge_with' # view for this action
  end

  # Custom route#action for searching people by name
  member_action :search_people, method: :post do
    @current_person = Person.find(params[:current_person_id])
    @search_query = params[:query]

    @search_results = PgSearch.multisearch(@search_query).where(searchable_type: 'Person') if @search_query.present?

    render 'admin/people/merge_with'
  end

  # Custom route#action for the 2nd view of merging - accept id of person to merge with
  member_action :preview_merge, method: :post do
    @current_person = Person.find(params[:current_person_id])
    @merge_with_person_id = params[:merge_with_person_id]

    if @merge_with_person_id.present?
      @merge_with_person = Person.find_by(id: @merge_with_person_id)

      if @merge_with_person.nil?
        flash.now[:error] = "Person with ID #{@merge_with_person_id} not found."
      elsif @merge_with_person.id == @current_person.id
        flash.now[:error] = 'Cannot merge a person with itself.'
        @merge_with_person = nil
      end
    end

    render 'admin/people/merge_with'
  end

  # Custom route#action for the action of merging - we have the two people now for the merge
  member_action :perform_merge, method: :post do
    source_person = Person.find(params[:current_person_id])
    replacement_person = Person.find(params[:merge_with_person_id])
    replacement_person_name = replacement_person.name

    source_person.merge!(replacement_person)
    redirect_to admin_person_path(source_person), notice: "Person successfully merged with #{replacement_person_name}."
  end
end
