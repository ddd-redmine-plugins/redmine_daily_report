# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  resources :ddd_daily_reports do
    collection do
      post :add_receiver
      post :remove_receiver
      get :receivers
    end
    collection do
      post :update_timelogs
      get :timelogs
    end
  end
  resources :ddd_timelogs, :only => [:index] do
    collection do
      post :update_issues
      get :issues
    end
  end
end
