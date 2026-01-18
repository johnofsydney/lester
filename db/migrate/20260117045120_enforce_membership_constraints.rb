class EnforceMembershipConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :memberships, :member_id, false
    change_column_null :memberships, :member_type, false
    # group_id already has an index to ensure it is not null

    # Remove the unique index on [:id, :group_id, :member_id]
    if index_exists?(:memberships, [:id, :group_id, :member_id], name: "index_memberships_on_id_and_group_id_and_member_id")
      remove_index :memberships, name: "index_memberships_on_id_and_group_id_and_member_id"
    end

    # Add a non-unique index on [:group_id, :member_type, :member_id]
    unless index_exists?(:memberships, [:group_id, :member_type, :member_id], name: "index_memberships_on_group_and_member")
      add_index :memberships, [:group_id, :member_type, :member_id], name: "index_memberships_on_group_and_member"
    end
  end
end
