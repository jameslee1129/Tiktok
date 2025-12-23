class SyncProductAnalytics
  class Error < StandardError; end

  def self.call(tik_tok_shop_id:, start_date:, end_date:)
    new(tik_tok_shop_id:, start_date:, end_date:).call
  end

  def initialize(tik_tok_shop_id:, start_date:, end_date:)
    @tik_tok_shop = TikTokShop.find(tik_tok_shop_id)
    @start_date = start_date.is_a?(String) ? Date.parse(start_date) : start_date
    @end_date = end_date.is_a?(String) ? Date.parse(end_date) : end_date
    @errors = []
  end

  def call
    # Process each day in the date range
    (@start_date..@end_date).each do |date|
      Rails.logger.info("Syncing products for date: #{date}")
      sync_date(date)
    end

    { success: @errors.empty?, errors: @errors }
  end

  private

  def sync_date(date)
    page = 0
    page_size = 50
    has_more = true

    while has_more
      response = fetch_page(date, page, page_size)
      
      unless response && response['status_code'] == 0
        @errors << "Failed to fetch page #{page} for date #{date}: #{response&.dig('status_msg')}"
        break
      end

      products_data = extract_products(response)
      
      if products_data.empty?
        has_more = false
        break
      end

      products_data.each do |product_data|
        upsert_product_and_snapshot(product_data, date)
      end

      # Check if there are more pages
      pagination = response.dig('data', 'list_control', 'pagination') || {}
      total_pages = pagination['total_page'] || 1
      has_more = page < total_pages - 1
      page += 1

      # Safety check to prevent infinite loops
      break if page > 1000
    end
  rescue => e
    @errors << "Error syncing date #{date}: #{e.message}"
    Rails.logger.error("Error syncing date #{date}: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def fetch_page(date, page, page_size)
    SignParamsService.get_products(
      cookie: @tik_tok_shop.cookie,
      oec_seller_id: @tik_tok_shop.oec_seller_id,
      base_url: @tik_tok_shop.base_url,
      fp: @tik_tok_shop.fp,
      timezone_offset: @tik_tok_shop.timezone_offset,
      start_date: date.to_s,
      end_date: (date + 1.day).to_s,
      page_no: page,
      page_size: page_size
    )
  end

  def extract_products(response)
    response.dig('data', 'product_list') || []
  end

  def upsert_product_and_snapshot(product_data, snapshot_date)
    external_id = product_data['product_id'] || product_data['id']
    return unless external_id

    # Upsert product
    product = TikTokShopProduct.find_or_initialize_by(
      tik_tok_shop_id: @tik_tok_shop.id,
      external_id: external_id
    )

    product.assign_attributes(
      title: product_data['title'] || product_data['product_name'],
      image_url: product_data['image_url'] || product_data['image'] || product_data['cover'],
      status: product_data['status'] || product_data['product_status'],
      stock: product_data['stock'] || product_data['stock_quantity'],
      raw_data: product_data.to_json
    )

    product.save!

    # Upsert snapshot
    snapshot = TikTokShopProductSnapshot.find_or_initialize_by(
      tik_tok_shop_product_id: product.id,
      snapshot_date: snapshot_date
    )

    # Extract metrics - adjust field names based on actual API response structure
    gmv = extract_decimal(product_data, ['gmv', 'total_gmv', 'gmv_amount'])
    items_sold = extract_integer(product_data, ['items_sold', 'quantity_sold', 'sold_quantity'])
    orders_count = extract_integer(product_data, ['orders_count', 'order_count', 'orders'])

    snapshot.assign_attributes(
      tik_tok_shop_id: @tik_tok_shop.id,
      gmv: gmv,
      items_sold: items_sold,
      orders_count: orders_count,
      raw_data: product_data.to_json
    )

    snapshot.save!
  rescue => e
    error_msg = "Error upserting product #{external_id} for date #{snapshot_date}: #{e.message}"
    @errors << error_msg
    Rails.logger.error("Error upserting product: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def extract_decimal(data, possible_keys)
    value = find_value(data, possible_keys)
    return 0.0 unless value
    
    case value
    when Numeric
      value.to_f
    when String
      value.gsub(/[^\d.-]/, '').to_f
    else
      0.0
    end
  end

  def extract_integer(data, possible_keys)
    value = find_value(data, possible_keys)
    return 0 unless value
    
    case value
    when Numeric
      value.to_i
    when String
      value.gsub(/[^\d-]/, '').to_i
    else
      0
    end
  end

  def find_value(data, possible_keys)
    possible_keys.each do |key|
      return data[key] if data.key?(key)
      return data[key.to_sym] if data.key?(key.to_sym)
    end
    nil
  end
end

