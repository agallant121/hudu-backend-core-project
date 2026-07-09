Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "companies/:id/dashboard", to: "companies#dashboard"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
