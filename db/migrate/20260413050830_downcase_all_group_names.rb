class DowncaseAllGroupNames < ActiveRecord::Migration[8.0]
  def change
    execute "UPDATE groups SET name = LOWER(name) WHERE name IS NOT NULL;"
  end
end
