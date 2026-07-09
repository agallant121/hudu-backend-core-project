module Api
  module V1
    class ReportsController < ApplicationController
      def company_comparison
        return unless valid_company_ids?

        data = CompanyComparisonQuery.call(company_ids:)

        render json: CompanyComparisonSerializer.new(data).as_json
      end

      private

      def company_ids
        @company_ids ||= Array(params[:company_ids]).reject(&:blank?)
      end

      def valid_company_ids?
        if company_ids.empty?
          render json: { error: "company_ids are required" }, status: :bad_request
          return false
        end

        unless company_ids.all? { |company_id| company_id.to_s.match?(/\A\d+\z/) }
          render json: { error: "company_ids must be integers" }, status: :bad_request
          return false
        end

        unless company_ids.size.between?(1, 50)
          render json: { error: "company_ids must include between 1 and 50 IDs" }, status: :bad_request
          return false
        end

        true
      end
    end
  end
end
