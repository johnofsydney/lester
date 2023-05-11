Rails.application.routes.draw do
  # resources :imports
  # get '/imports/annual_associated_entity' => 'imports#annual_associated_entity'
  # post '/imports/annual_associated_entity_upload' => 'imports#annual_associated_entity_upload'

  get '/imports/annual_donor' => 'imports#annual_donor'
  post '/imports/annual_donor_upload' => 'imports#annual_donor_upload'

  # resources :friendships
  resources :groups
  # resources :evidences
  resources :people
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
