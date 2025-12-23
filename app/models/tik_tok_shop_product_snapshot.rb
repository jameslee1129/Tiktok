class TikTokShopProductSnapshot
  include Mongoid::Document
  include Mongoid::Timestamps

  field :snapshot_date, type: Date
  field :gmv, type: BigDecimal, default: 0
  field :items_sold, type: Integer, default: 0
  field :orders_count, type: Integer, default: 0
  field :raw_data, type: String

  belongs_to :tik_tok_shop
  belongs_to :tik_tok_shop_product

  validates :snapshot_date, presence: true
  validates :snapshot_date, uniqueness: { scope: :tik_tok_shop_product_id }
  validates :gmv, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :items_sold, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :orders_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  index({ tik_tok_shop_product_id: 1, snapshot_date: 1 }, { unique: true })
  index({ tik_tok_shop_id: 1, snapshot_date: 1 })
end

