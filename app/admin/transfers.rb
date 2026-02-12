ActiveAdmin.register Transfer do
  permit_params :giver_type, :giver_id, :taker_id, :amount, :evidence, :transfer_type, :effective_date, :data

  # Add a "Confirm Value" button on the show page
  action_item :confirm_value, only: :show do
    link_to 'Confirm Value', confirm_value_admin_transfer_path(resource), method: :get
  end

  member_action :confirm_value, method: :get do
    resource.data ||= {}
    resource.data['value_confirmed'] = true
    resource.save!
    redirect_to admin_transfer_path(resource), notice: 'Value for this transfer has been confirmed.'
  end
end
