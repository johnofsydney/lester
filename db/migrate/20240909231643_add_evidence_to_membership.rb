class AddEvidenceToMembership < ActiveRecord::Migration[7.0]
  def change
    add_column :memberships, :evidence, :string
  end
end
