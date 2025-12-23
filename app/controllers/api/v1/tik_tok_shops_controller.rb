module Api
  module V1
    class TikTokShopsController < ApplicationController
      def product_analytics
        tik_tok_shop_id = params[:id]
        start_date = params[:start_date]
        end_date = params[:end_date]
        min_gmv = params[:min_gmv]&.to_f

        # Validate required parameters
        unless start_date && end_date
          return render json: { error: 'start_date and end_date are required' }, status: :bad_request
        end

        begin
          results = ProductAnalyticsQuery.call(
            tik_tok_shop_id: tik_tok_shop_id,
            start_date: start_date,
            end_date: end_date,
            min_gmv_cents: min_gmv ? (min_gmv * 100).to_i : nil
          )

          render json: { data: results }
        rescue => e
          Rails.logger.error("Error fetching product analytics: #{e.message}\n#{e.backtrace.join("\n")}")
          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
  end
end

