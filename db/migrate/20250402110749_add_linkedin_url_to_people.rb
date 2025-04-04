class AddLinkedinUrlToPeople < ActiveRecord::Migration[7.0]
  def change
    add_column :people, :linkedin_url, :string
  end
end
