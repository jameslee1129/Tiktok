class ProductAnalyticsQuery
  def self.call(tik_tok_shop_id:, start_date:, end_date:, min_gmv_cents: nil)
    new(tik_tok_shop_id:, start_date:, end_date:, min_gmv_cents:).call
  end

  def initialize(tik_tok_shop_id:, start_date:, end_date:, min_gmv_cents: nil)
    @tik_tok_shop = TikTokShop.find(tik_tok_shop_id)
    @start_date = start_date.is_a?(String) ? Date.parse(start_date) : start_date
    @end_date = end_date.is_a?(String) ? Date.parse(end_date) : end_date
    @min_gmv_cents = min_gmv_cents
  end

  def call
    # MongoDB aggregation pipeline
    pipeline = [
      # Match snapshots in date range for this shop
      {
        '$match' => {
          'tik_tok_shop_id' => BSON::ObjectId(@tik_tok_shop.id.to_s),
          'snapshot_date' => { '$gte' => @start_date, '$lte' => @end_date }
        }
      },
      # Lookup the product
      {
        '$lookup' => {
          'from' => TikTokShopProduct.collection.name,
          'localField' => 'tik_tok_shop_product_id',
          'foreignField' => '_id',
          'as' => 'product'
        }
      },
      # Unwind the product array (should only be one)
      { '$unwind' => '$product' },
      # Group by product and aggregate metrics
      {
        '$group' => {
          '_id' => '$product._id',
          'external_id' => { '$first' => '$product.external_id' },
          'title' => { '$first' => '$product.title' },
          'status' => { '$first' => '$product.status' },
          'image_url' => { '$first' => '$product.image_url' },
          'total_gmv' => { '$sum' => '$gmv' },
          'total_items_sold' => { '$sum' => '$items_sold' },
          'total_orders_count' => { '$sum' => '$orders_count' }
        }
      }
    ]

    # Apply GMV filter if provided
    if @min_gmv_cents
      min_gmv = @min_gmv_cents / 100.0
      pipeline << {
        '$match' => {
          'total_gmv' => { '$gte' => min_gmv }
        }
      }
    end

    # Execute aggregation
    results = TikTokShopProductSnapshot.collection.aggregate(pipeline).to_a

    # Convert to array of hashes
    results.map do |row|
      {
        external_id: row['external_id'],
        title: row['title'],
        status: row['status'],
        image_url: row['image_url'],
        gmv: row['total_gmv'].to_f,
        items_sold: row['total_items_sold'].to_i,
        orders_count: row['total_orders_count'].to_i
      }
    end
  end
end

