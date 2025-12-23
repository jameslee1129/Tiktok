class TikTokShopProduct
  include Mongoid::Document
  include Mongoid::Timestamps

  field :external_id, type: String
  field :title, type: String
  field :image_url, type: String
  field :status, type: String
  field :stock, type: Integer
  field :raw_data, type: String

  belongs_to :tik_tok_shop
  has_many :tik_tok_shop_product_snapshots, dependent: :destroy

  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :tik_tok_shop_id }

  index({ tik_tok_shop_id: 1, external_id: 1 }, { unique: true })
end

