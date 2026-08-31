class EnableTrigramSearch < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'pg_trgm'
    enable_extension 'unaccent'

    add_index :pg_search_documents, :content, using: :gin, opclass: :gin_trgm_ops,
                                                name: 'index_pg_search_documents_on_content_trgm'

    # Backs the advanced-search group typeahead (~130k groups, too many for a <select>).
    add_index :groups, :name, using: :gin, opclass: :gin_trgm_ops,
                               name: 'index_groups_on_name_trgm'
  end
end
