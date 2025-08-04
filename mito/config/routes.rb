Rails.application.routes.draw do
  devise_for :users
  
  root 'chats#show'
  
  # Anonymous messaging for non-authenticated users
  post 'anonymous_messages', to: 'anonymous_messages#create', as: :anonymous_messages
  
  # Authenticated user chats
  resources :chats, only: [:index, :show, :create, :destroy] do
    resources :messages, only: [:create]
  end
  
  # Admin-only sources management
  resources :sources, only: [:index, :show]
  
  # Admin dashboard
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    root 'dashboard#index'
  end
  
  get "up" => "rails/health#show", as: :rails_health_check
end
