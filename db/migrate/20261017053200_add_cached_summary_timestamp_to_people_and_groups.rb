class AddCachedSummaryTimestampToPeopleAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :cached_summary_timestamp, :datetime
    add_column :groups, :cached_summary_timestamp, :datetime
  end
end
