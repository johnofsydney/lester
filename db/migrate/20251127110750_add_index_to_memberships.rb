class AddIndexToMemberships < ActiveRecord::Migration[7.2]
  def change
    add_index :memberships, [:group_id, :member_type, :member_id], name: 'index_memberships_on_group_and_member'
  end
end
