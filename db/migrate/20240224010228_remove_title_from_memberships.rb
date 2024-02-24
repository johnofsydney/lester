class RemoveTitleFromMemberships < ActiveRecord::Migration[7.0]
  def change
    remove_column :memberships, :title, :string
  end
end
