class DowncaseAllPeopleNames < ActiveRecord::Migration[8.0]
  def change
    execute "UPDATE people SET name = LOWER(name) WHERE name IS NOT NULL;"
  end
end
