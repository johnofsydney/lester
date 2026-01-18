class EnforcePositionConstraints < ActiveRecord::Migration[8.0]
  def change
    Position.where(title: nil).destroy_all

    change_column_null :positions, :title, false
  end
end
