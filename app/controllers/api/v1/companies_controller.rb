module Api
  module V1
    class CompaniesController < ApplicationController
      def dashboard
        company = Company.find(params[:id])
        data = CompanyDashboardQuery.call(company:)

        render json: CompanyDashboardSerializer.new(data).as_json
      end
    end
  end
end
