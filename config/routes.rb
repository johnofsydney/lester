require 'sidekiq/web' # require the web UI

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  authenticate :admin_user do
    mount Flipper::UI.app(Flipper) => '/flipper'
    mount Sidekiq::Web => '/sidekiq'
    mount MaintenanceTasks::Engine, at: '/maintenance_tasks'
  end

  mount Prettytodo::Engine => '/prettytodo' if Rails.env.development?

  namespace :api do
    namespace :v1 do
      get 'health' => 'health#show'
    end
  end

  get 'groups/group_people/:group_id' => 'groups#group_people'
  get 'groups/affiliated_groups/:group_id' => 'groups#affiliated_groups'
  get 'groups/money_summary/:group_id' => 'groups#money_summary'
  get 'groups/:id/reload' => 'groups#reload'

  get 'people/:id/network_graph' => 'inertia#network_graph_person'
  get 'groups/:id/network_graph' => 'inertia#network_graph_group'

  get 'search' => 'search#index'

  get '/post_to_socials' => 'home#post_to_socials'              # Random
  get '/people/:id/post_to_socials' => 'people#post_to_socials' # Person

  get '/people/:id/reload' => 'people#reload'
  get '/tradingnames/:id' => 'trading_names#show'
  get '/tags/:id' => 'groups#show'

  resources :transfers
  resources :groups
  resources :people

  get '/home/todo' => 'home#todo'
  get '/todo' => 'home#todo'

  get '/home/index' => 'home#index'
  get '/about' => 'home#index'
  # Defines the root path route ("/")
  # root "articles#index"
  root 'search#index'

  # # Add a custom POST route for Memberships
  post '/admin/memberships/general_upload_action', to: 'admin/memberships#general_upload_action', as: :general_upload_action_admin_memberships
  post '/admin/memberships/ministries_upload_action', to: 'admin/memberships#ministries_upload_action', as: :ministries_upload_action_admin_memberships
  post '/admin/groups/perform_merge', to: 'admin/groups#perform_merge'
  post '/admin/people/ingest_linkedin', to: 'admin/people#ingest_linkedin'
end