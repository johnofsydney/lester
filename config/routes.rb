Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  get 'search' => 'search#index'
  get 'linker' => 'search#linker'
  get '/home/suggestions' => 'home#suggestions'
  get '/home/suggestion_received' => 'home#suggestion_received'
  post '/home/post_suggestions' => 'home#post_suggestions'

  get '/imports/' => 'imports#index'
  post '/imports/annual_donor_upload' => 'imports#annual_donor_upload'
  post '/imports/federal_parliamentarians_upload' => 'imports#federal_parliamentarians_upload'
  post '/imports/people_upload' => 'imports#people_upload'
  post '/imports/groups_upload' => 'imports#groups_upload'

  resources :transactions do
    collection do
      get :summary
    end
  end
  resources :transfers
  resources :groups
  resources :people
  resources :activity_feed
  resources :people_transfers
  resources :transfer_details
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get '/home/todo' => 'home#todo'
  get '/todo' => 'home#todo'

  get '/home/index' => 'home#index'
  get '/about' => 'home#index'
  # Defines the root path route ("/")
  # root "articles#index"
  root "search#index"
end