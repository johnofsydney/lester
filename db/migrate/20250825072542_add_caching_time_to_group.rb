class AddCachingTimeToGroup < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :last_cached, :datetime
  end
end
