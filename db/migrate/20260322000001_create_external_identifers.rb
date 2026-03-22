class CreateExternalIdentifers < ActiveRecord::Migration[8.0]
  def change
    create_table :external_identifers do |t|
      t.string :owner_type, null: false
      t.bigint :owner_id,   null: false
      t.string :source,     null: false  # e.g. 'aec', 'acnc', 'open_politics'
      t.string :value,      null: false

      t.timestamps
    end

    add_index :external_identifers, [:owner_type, :owner_id], name: 'index_external_identifers_on_owner'
    add_index :external_identifers, [:source, :value],        name: 'index_external_identifers_on_source_and_value', unique: true
    add_index :external_identifers, [:owner_type, :owner_id, :source],
              name: 'index_external_identifers_on_owner_and_source', unique: true
  end
end
