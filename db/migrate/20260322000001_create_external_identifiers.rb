class CreateExternalIdentifiers < ActiveRecord::Migration[8.0]
  def change
    create_table :external_identifiers do |t|
      t.string :owner_type, null: false
      t.bigint :owner_id,   null: false
      t.string :source,     null: false  # e.g. 'aec', 'acnc', 'open_politics'
      t.string :value,      null: false

      t.timestamps
    end

    add_index :external_identifiers, [:owner_type, :owner_id], name: 'index_external_identifiers_on_owner'
    add_index :external_identifiers, [:source, :value],        name: 'index_external_identifiers_on_source_and_value', unique: true
    add_index :external_identifiers, [:owner_type, :owner_id, :source],
              name: 'index_external_identifiers_on_owner_and_source', unique: true
  end
end
