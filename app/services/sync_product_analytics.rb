require 'bigdecimal'
require 'bigdecimal/util'

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
      Rails.logger.info("RAW RESPONSE: #{response.inspect}")

      unless response &&( response['code'] == 0 || response.key?('items'))
        @errors << "Failed to fetch page #{page} for date #{date}: #{response&.dig('message')}"
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
      pagination = response.dig('data', 'next_pagination') || {}
      has_more = pagination['has_more']
      page = pagination['next_page'] || page + 1

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
    response.dig('data', 'items') || []
  end

  def upsert_product_and_snapshot(product_data, snapshot_date)
    meta  = product_data['meta']
    stats = product_data['stats']
    external_id = meta['product_id']
    # Upsert product
    product = TikTokShopProduct.find_or_initialize_by(
      tik_tok_shop_id: @tik_tok_shop.id,
      external_id: external_id
    )

    product.assign_attributes(
      title: meta['product_name'],
      image_url: meta['product_image'],
      status: map_status(meta['product_status']),
      stock: meta['inventory_cnt'],
      raw_data: meta.to_json
    )

    # product.save!

    # Upsert snapshot
    snapshot = TikTokShopProductSnapshot.find_or_initialize_by(
      tik_tok_shop_product: product,
      snapshot_date: snapshot_date
    )

    snapshot.assign_attributes(
      tik_tok_shop_id: @tik_tok_shop.id,
      gmv: stats.dig('gmv', 'amount').to_d,
      items_sold: stats['unit_sold_cnt'] || 0,
      orders_count: stats['order_cnt'] || 0,
      raw_data: stats.to_json
    )

    # snapshot.save!

    # begin
    # Mongoid::Clients.default.start_session do |session| # only if using replica set or atlas 
    #   session.with_transaction do
    #     product.save!
    #     snapshot.save!
    #   end
    # end
    # If not using transactions, uncomment below
    product.save!
    snapshot.save!
  rescue => e
    error_msg = "Error upserting product #{external_id} for date #{snapshot_date}: #{e.message}"
    @errors << error_msg
    Rails.logger.error("Error upserting product: #{e.message}\n#{e.backtrace.join("\n")}")
  end


  def map_status(value)
    case value
    when 1 then 'live'
    when 0 then 'hidden'
    else 'unknown'
    end
  end

  # def extract_decimal(data, possible_keys)
  #   value = find_value(data, possible_keys)
  #   return 0.0 unless value
    
  #   case value
  #   when Numeric
  #     value.to_f
  #   when String
  #     value.gsub(/[^\d.-]/, '').to_f
  #   else
  #     0.0
  #   end
  # end

  # def extract_integer(data, possible_keys)
  #   value = find_value(data, possible_keys)
  #   return 0 unless value
    
  #   case value
  #   when Numeric
  #     value.to_i
  #   when String
  #     value.gsub(/[^\d-]/, '').to_i
  #   else
  #     0
  #   end
  # end

  # def find_value(data, possible_keys)
  #   possible_keys.each do |key|
  #     return data[key] if data.key?(key)
  #     return data[key.to_sym] if data.key?(key.to_sym)
  #   end
  #   nil
  # end
end

