Rails.application.routes.draw do
  get 'home/index'
  
  get '/bemvindo' => 'home#index'
  #resources :home, only: [:show]

  root 'home#index'

  resources :phones
  resources :addresses
  resources :contacts #, only: [:show]
  resources :kinds #, except: [:edit]
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
