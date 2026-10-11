ActiveAdmin.register IngestSourceStatus do
  menu label: 'Source Health'

  actions :index, :show

  filter :key
  filter :last_run_at
  filter :last_success_at
  filter :last_failure_at

  index do
    selectable_column
    column :key
    column :last_run_at
    column :last_success_at
    column :last_failure_at
    column 'Status' do |status|
      if status.failing?
        status_tag 'Failing', class: 'red'
      else
        status_tag 'OK', class: 'green'
      end
    end
    actions
  end

  show do
    attributes_table do
      row :key
      row :last_run_at
      row :last_success_at
      row :last_failure_at
      row :last_error
      row('Status') do |status|
        status.failing? ? status_tag('Failing', class: 'red') : status_tag('OK', class: 'green')
      end
    end
  end
end
