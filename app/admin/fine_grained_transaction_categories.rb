ActiveAdmin.register FineGrainedTransactionCategory do
  permit_params :name, :major_transaction_category_id

  filter :name
  filter :major_transaction_category

  index do
    selectable_column
    id_column
    column :name
    column :major_transaction_category
    column('Transactions') { |fine_grained| fine_grained.individual_transactions.count }
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :major_transaction_category
      row('Transactions') { resource.individual_transactions.count }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :major_transaction_category
    end
    f.actions
  end

  batch_action :assign_to_major_category, form: lambda {
    {
      major_transaction_category_id: MajorTransactionCategory.pluck(:name, :id)
    }
  } do |ids, inputs|
    major_category = MajorTransactionCategory.find(inputs[:major_transaction_category_id])

    FineGrainedTransactionCategory.where(id: ids).find_each do |fine_grained|
      fine_grained.update!(major_transaction_category: major_category)
    end

    redirect_to collection_path, notice: "Assigned #{ids.size} categories to #{major_category.name}."
  end
end
