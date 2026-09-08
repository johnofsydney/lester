class AddTrigramSearchToPgSearchDocuments < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pg_trgm'
    enable_extension 'unaccent'

    add_index :pg_search_documents, :content, using: :gin, opclass: :gin_trgm_ops,
                                              name: 'index_pg_search_documents_on_content_trigram'
  end
end
