class AddReviewedToLeadershipWebsite < ActiveRecord::Migration[8.0]
  def change
    add_column :leadership_websites, :reviewed_at, :date
  end
end
