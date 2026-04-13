class DeleteLastRefreshedFromGroups < ActiveRecord::Migration[8.0]
  def change
    remove_column :groups, :last_refreshed, :date
  end
end
