ActiveAdmin.register ApiLog do
  actions :index, :show, :destroy

  filter :endpoint
  filter :message
  filter :created_at

  index do
    selectable_column
    id_column
    column :endpoint
    column :message
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :endpoint
      row :message
      row :created_at
    end
  end
end
