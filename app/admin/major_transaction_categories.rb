ActiveAdmin.register MajorTransactionCategory do
  permit_params :name

  filter :name

  index do
    selectable_column
    id_column
    column :name
    column('Fine-Grained Categories') { |major| major.fine_grained_transaction_categories.count }
    column('Transactions') { |major| major.individual_transactions.count }
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :created_at
      row :updated_at
    end

    panel 'Fine-Grained Categories' do
      table_for resource.fine_grained_transaction_categories.order(:name) do
        column :name
        column('Transactions') { |fine_grained| fine_grained.individual_transactions.count }
        column '' do |fine_grained|
          link_to 'View', admin_fine_grained_transaction_category_path(fine_grained)
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end
end
