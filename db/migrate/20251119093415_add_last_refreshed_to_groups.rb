class AddLastRefreshedToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :last_refreshed, :date
  end
end
