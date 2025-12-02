class AddMissingIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :memberships, :start_date unless index_exists?(:memberships, :start_date)
    add_index :memberships, :end_date unless index_exists?(:memberships, :end_date)
    add_index :memberships, [:start_date, :end_date] unless index_exists?(:memberships, [:start_date, :end_date])

    add_index :groups, :name unless index_exists?(:groups, :name)
    add_index :groups, :category unless index_exists?(:groups, :category)
    add_index :groups, :business_number, unique: true, name: 'index_groups_on_business_number' unless index_exists?(:groups, :business_number)

    add_index :people, :name unless index_exists?(:people, :name)
  end
end
