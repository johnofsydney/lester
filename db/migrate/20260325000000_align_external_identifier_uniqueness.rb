class AlignExternalIdentifierUniqueness < ActiveRecord::Migration[8.0]
  def change
    remove_index :external_identifiers, name: 'index_external_identifiers_on_owner_and_source'
    remove_index :external_identifiers, name: 'index_external_identifiers_on_source_and_value'

    add_index :external_identifiers,
              %i[owner_type owner_id source value],
              unique: true,
              name: 'index_external_identifiers_on_owner_source_and_value'

    add_index :external_identifiers,
              %i[source value],
              name: 'index_external_identifiers_on_source_and_value'
  end
end
