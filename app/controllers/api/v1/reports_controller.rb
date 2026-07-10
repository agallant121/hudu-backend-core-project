module Api
  module V1
    class ReportsController < ApplicationController
      def company_comparison
        return unless valid_company_ids?

        data = Reports::CompanyComparisonQuery.call(company_ids:)

        render json: Reports::CompanyComparisonSerializer.new(data).as_json
      end

      def expiring_licenses
        return unless valid_days?

        data = Reports::ExpiringLicensesQuery.call(days:)

        render json: Reports::ExpiringLicensesSerializer.new(data).as_json
      end

      def maintenance_costs
        return unless valid_maintenance_cost_dates?

        data = Reports::MaintenanceCostsQuery.call(start_date:, end_date:)

        render json: Reports::MaintenanceCostsSerializer.new(data).as_json
      end

      private

      def company_ids
        @company_ids ||= Array(params[:company_ids]).reject(&:blank?)
      end

      def days
        @days ||= days_param.to_i
      end

      def days_param
        @days_param ||= params[:days].presence || "30"
      end

      def start_date
        @start_date ||= parse_date(params[:start_date])
      end

      def end_date
        @end_date ||= parse_date(params[:end_date])
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

      def valid_days?
        unless days_param.to_s.match?(/\A\d+\z/)
          render json: { error: "days must be a non-negative integer" }, status: :bad_request
          return false
        end

        true
      end

      def valid_maintenance_cost_dates?
        unless valid_date_param?(params[:start_date]) && valid_date_param?(params[:end_date])
          render json: { error: "start_date and end_date must be valid dates in YYYY-MM-DD format" }, status: :bad_request
          return false
        end

        if start_date > end_date
          render json: { error: "start_date must be on or before end_date" }, status: :bad_request
          return false
        end

        true
      end

      def valid_date_param?(value)
        return false unless value.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)

        parse_date(value).present?
      end

      def parse_date(value)
        Date.iso8601(value)
      rescue Date::Error
        nil
      end
    end
  end
end
