Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "assets/:id", to: "assets#show"
      get "companies/:id/dashboard", to: "companies#dashboard"
      get "reports/company_comparison", to: "reports#company_comparison"
      get "reports/expiring_licenses", to: "reports#expiring_licenses"
      get "reports/maintenance_costs", to: "reports#maintenance_costs"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
