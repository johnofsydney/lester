ActiveAdmin.register TradingName do
  actions :index, :show, :new, :create, :edit, :update, :destroy

  permit_params :name, :owner_type, :owner_id

  filter :name
  filter :owner_type, as: :select, collection: %w[Person Group]
  filter :source, as: :select, collection: TradingName::SOURCES
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :owner_type, as: :select, collection: %w[Person Group], include_blank: false
      f.input :owner_id
    end
    f.actions
  end

  before_create do |trading_name|
    trading_name.source = 'manual'
  end

  controller do
    def scoped_collection
      super.includes(:owner)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :source
    column :owner_type
    column :owner do |trading_name|
      case trading_name.owner_type
      when 'Person' then link_to trading_name.owner.name, admin_person_path(trading_name.owner_id)
      when 'Group' then link_to trading_name.owner.name, admin_group_path(trading_name.owner_id)
      end
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :source
      row :owner_type
      row :owner do |trading_name|
        case trading_name.owner_type
        when 'Person' then link_to trading_name.owner.name, admin_person_path(trading_name.owner_id)
        when 'Group' then link_to trading_name.owner.name, admin_group_path(trading_name.owner_id)
        end
      end
      row :created_at
    end
  end
end
