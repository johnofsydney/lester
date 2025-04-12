Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount Flipper::UI.app(Flipper) => '/flipper'

  get 'groups/page=:page' => 'groups#index'
  get 'people/page=:page' => 'people#index'
  get 'transfers/page=:page' => 'transfers#index'

  get 'groups/group_people/:group_id/page=:page' => 'groups#group_people'
  get 'groups/affiliated_groups/:group_id/page=:page' => 'groups#affiliated_groups'
  get 'groups/money_summary/:group_id' => 'groups#money_summary'

  get 'people/:id/network_graph' => 'inertia#network_graph_person'
  get 'groups/:id/network_graph' => 'inertia#network_graph_group'

  get 'search' => 'search#index'
  get '/home/suggestions' => 'home#suggestions'

  get '/post_to_socials' => 'home#post_to_socials'              # Random
  get '/people/:id/post_to_socials' => 'people#post_to_socials' # Person

  resources :transfers
  resources :groups
  resources :people

  # todo: remove these
  resources :lazy_load_groups
  resources :lazy_load_people
  resources :lazy_load_transfers
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get '/home/todo' => 'home#todo'
  get '/todo' => 'home#todo'

  get '/home/index' => 'home#index'
  get '/about' => 'home#index'
  # Defines the root path route ("/")
  # root "articles#index"
  root "search#index"


  # # Add a custom POST route for Memberships
  post '/admin/memberships/custom_action', to: 'admin/memberships#custom_action', as: :custom_admin_memberships
  post '/admin/groups/perform_merge', to: 'admin/groups#perform_merge'
  post '/admin/people/ingest_linkedin', to: 'admin/people#ingest_linkedin'
end