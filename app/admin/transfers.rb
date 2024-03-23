ActiveAdmin.register Transfer do
  permit_params :giver_type, :giver_id, :taker_id, :amount, :evidence, :transfer_type, :effective_date, :data

end
