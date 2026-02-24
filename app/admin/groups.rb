ActiveAdmin.register Group do

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

  permit_params :name, :business_number

  filter :id
  filter :name
  filter :type

  index do
    selectable_column
    id_column
    column(:name, sortable: 'name')
    column(:business_number, sortable: 'business_number')
    column('Memberships (as owning group)') do |group|
      group.memberships.count
    end
    column('Transfers In') do |group|
      number_to_currency group.incoming_transfers.sum(:amount), precision: 0
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :business_number
      row :type
      row :created_at
      row :updated_at
      row('Memberships (as owning group)') { Membership.where(group: resource).count }
      row('Memberships (as member)') { Membership.where(member: resource).count }
      row('Direct Transfers In') { number_to_currency resource.incoming_transfers.sum(:amount), precision: 0 }
      row('Direct Transfers Out') { number_to_currency resource.outgoing_transfers.sum(:amount), precision: 0 }
    end

    panel 'Memberships (as owning group)' do
      table_for resource.memberships.order(created_at: :desc) do
        column :id do |membership|
          link_to membership.id, admin_membership_path(membership)
        end
        column :member do |membership|
          path = if membership.member_type == 'Person'
                   admin_person_path(membership.member)
                 elsif membership.member_type == 'Group'
                   admin_group_path(membership.member)
                 end

          link_to membership.member.name, path
        end
        column :member_type
        column :position
        column :start_date
        column :end_date
        column :created_at
      end
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
    f.inputs do
      f.input :name
      f.input :business_number
      # f.input :category
    end
    f.actions
  end

  action_item :view_group, only: :show do
    link_to 'View Group', group_path(resource), method: :get
  end

  action_item :refresh_from_abn, only: :show do
    link_to 'Refresh from ABN', refresh_from_abn_admin_group_path(resource), method: :get
  end

  # Add a "Merge With" button on the show page
  action_item :merge_with, only: :show do
    link_to 'Merge With', merge_with_admin_group_path(resource), method: :get
  end

  member_action :refresh_from_abn, method: :get do
    UpdateGroupNamesFromAbnJob.perform_async(resource.id)
    redirect_to admin_group_path(resource), notice: 'Refresh from ABN Queued.'
  end

  # Custom route#action for the initial view of merging
  member_action :merge_with, method: :get do
    @current_group = resource
    render 'admin/groups/merge_with' # view for this action
  end

  # Custom route#action for searching groups by name
  member_action :search_groups, method: :post do
    @current_group = Group.find(params[:current_group_id])
    @search_query = params[:query]

    @search_results = PgSearch.multisearch(@search_query).where(searchable_type: 'Group') if @search_query.present?

    render 'admin/groups/merge_with'
  end

  # Custom route#action for the 2nd view of merging - accept id of group to merge with
  member_action :preview_merge, method: :post do
    @current_group = Group.find(params[:current_group_id])
    @merge_with_group_id = params[:merge_with_group_id]

    if @merge_with_group_id.present?
      @merge_with_group = Group.find_by(id: @merge_with_group_id)

      if @merge_with_group.nil?
        flash.now[:error] = "Group with ID #{@merge_with_group_id} not found."
      elsif @merge_with_group.id == @current_group.id
        flash.now[:error] = 'Cannot merge a group with itself.'
        @merge_with_group = nil
      end
    end

    render 'admin/groups/merge_with'
  end

  # Custom route#action for the action of merging - we have the two groups now for the merge
  member_action :perform_merge, method: :post do
    source_group = Group.find(params[:current_group_id])
    replacement_group = Group.find(params[:merge_with_group_id])
    replacement_group_name = replacement_group.name

    source_group.merge!(replacement_group)
    redirect_to admin_group_path(source_group), notice: "Group successfully merged with #{replacement_group_name}."
  end

  batch_action :add_to_tag, form: -> {
    {
      tag_id: Group.other_tags.map { |c| [c.name, c.id] }
    }
  } do |ids, inputs|
    tag = Group.find(inputs[:tag_id])

    # TODO: use a service
    Group.where(id: ids).find_each do |group|
      Membership.create(
        group: tag,
        member: group,
        member_type: 'Group'
      )
    end

    redirect_to collection_path, alert: "Groups added to #{tag.name}."
  end

  controller do
    def destroy
      @group = Group.find(params[:id])

      has_memberships_as_owner = @group.memberships.exists?
      has_memberships_as_member = Membership.where(member: @group).exists?
      has_incoming_transfers = @group.incoming_transfers.exists?
      has_outgoing_transfers = @group.outgoing_transfers.exists?

      if has_memberships_as_owner || has_memberships_as_member || has_incoming_transfers || has_outgoing_transfers
        flash[:error] = 'Cannot delete group with existing memberships or transfers.'
        redirect_to admin_group_path(@group)
      else
        @group.destroy
        flash[:notice] = 'Group deleted successfully.'
        redirect_to admin_groups_path
      end
    end
  end
end
