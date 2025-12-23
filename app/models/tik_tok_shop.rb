class TikTokShop
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :cookie, type: String
  field :oec_seller_id, type: String
  field :base_url, type: String, default: 'https://seller-us.tiktok.com'
  field :fp, type: String
  field :timezone_offset, type: Integer, default: -28800
  field :region, type: String, default: 'US'

  has_many :tik_tok_shop_products, dependent: :destroy
  has_many :tik_tok_shop_product_snapshots, dependent: :destroy

  validates :oec_seller_id, presence: true
  validates :cookie, presence: true
  validates :base_url, presence: true
end

