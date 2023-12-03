Rails.application.routes.draw do
  get '/imports/annual_donor' => 'imports#annual_donor'
  post '/imports/annual_donor_upload' => 'imports#annual_donor_upload'

  resources :transactions do
    collection do
      get :summary
    end
  end
  resources :transfers
  resources :groups
  resources :people
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "home#index"
end