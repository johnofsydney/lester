class AddCompoundIndexToMemberships < ActiveRecord::Migration[6.1]
  def change
    add_index :memberships, [:id, :group_id, :member_id], unique: true, name: 'index_memberships_on_id_and_group_id_and_member_id'
  end
end