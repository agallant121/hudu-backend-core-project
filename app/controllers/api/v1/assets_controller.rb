module Api
  module V1
    class AssetsController < ApplicationController
      def show
        asset = Asset.find(params[:id])
        data = AssetDetailQuery.call(asset:)

        render json: AssetDetailSerializer.new(data).as_json
      end
    end
  end
end
