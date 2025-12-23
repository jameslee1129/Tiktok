require 'open3'
require 'json'

class SignParamsService
  PRODUCTS_RUNNER = Rails.root.join('app/javascript/products.mjs')

  def self.get_products(
    cookie:,
    oec_seller_id:,
    base_url:,
    fp:,
    timezone_offset:,
    start_date:,
    end_date:,
    page_no: 0,
    page_size: 10
  )
    # Prepare input data as JSON
    input_data = {
      cookie:,
      oecSellerId: oec_seller_id,
      baseUrl: base_url,
      fp:,
      timezoneOffset: timezone_offset,
      startDate: start_date,
      endDate: end_date,
      pageNo: page_no,
      pageSize: page_size
    }.compact.to_json

    # Pass data via stdin to avoid shell escaping issues
    stdout, stderr, status = Open3.capture3(
      'node',
      PRODUCTS_RUNNER.to_s,
      stdin_data: input_data
    )

    unless status.success?
      Rails.logger.error("Node request failed: #{stderr}")
      Rails.logger.error("Node stdout: #{stdout}")
      raise "Request failed: #{stderr}"
    end

    # Parse and return the response
    begin
      JSON.parse(stdout.strip)
    rescue JSON::ParserError => e
      Rails.logger.error("JSON parse error. stdout: #{stdout}, stderr: #{stderr}")
      raise "JSON parse error: #{e.message}. Output: #{stdout[0..500]}"
    end
  end
end

