# TikTok Shop Product Analytics → Daily Snapshots → Query API

> **📖 Quick Links:**
> - [Real Testing Flow](REAL_TESTING_FLOW.md) - Step-by-step testing guide
> - [How to Get Shop ID](HOW_TO_GET_SHOP_ID.md) - Find your TikTok shop ID
> - [Install Ruby on Windows](INSTALL_RUBY.md) - Ruby/Bundler setup

## Part A - Discovered Endpoint

### Request URL / Path
```
POST https://seller-us.tiktok.com/api/v2/insights/seller/ttp/product/list/v2
```

### Key Parameters (Query String)
- `locale=en`
- `language=en`
- `oec_seller_id=7496020242935155064`
- `aid=4068`
- `app_name=i18n_ecom_shop`
- `fp=verify_mikvoq3z_Aejdw0Hu_C50w_4kN9_92s6_MdfQONpspa58`
- `device_platform=web`
- `cookie_enabled=true`
- `screen_width=1512`
- `screen_height=982`
- `browser_language=en-US`
- `browser_platform=MacIntel`
- `browser_name=Mozilla`
- `browser_version=5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36`
- `browser_online=true`
- `timezone_name=America/New_York`
- `use_content_type_definition=1`
- `msToken=<generated>`
- `X-Bogus=<generated>`
- `X-Gnarly=<generated>`

### Request Body
```json
{
  "request": {
    "time_descriptor": {
      "start": "2025-12-17",
      "end": "2025-12-18",
      "timezone_offset": -28800
    },
    "ccr_available_date": "2025-12-15",
    "search": {
      "voc_statuses": [],
      "gmv_ranges": []
    },
    "filter": {},
    "list_control": {
      "rules": [
        {
          "direction": 2,
          "field": "gmv"
        }
      ],
      "pagination": {
        "size": 10,
        "page": 0
      }
    }
  }
}
```

### Response Structure
The response includes product-level rows containing:
- Product name/title
- Product ID (external ID)
- Image (or image URL)
- Status (live/hidden, etc.)
- GMV
- Items sold
- Number of orders
- Stock status
- Optional metrics (shop tab page views, impressions, etc.)

### Notes
- Requires authentication via cookies
- Uses special tokens: `X-Bogus` and `X-Gnarly` (generated using encryption functions)
- Supports pagination via `list_control.pagination`
- Date range is specified in `time_descriptor.start` and `time_descriptor.end`

---

## Setup Instructions

### Prerequisites
- Node.js (v14+)
- Ruby (v3.0+)
- Rails (v7.0+)
- MongoDB (v4.4+)

### Installation

1. **Install Node.js dependencies:**
```bash
npm install
```

2. **Install Ruby dependencies:**
```bash
bundle install
```

3. **Set up MongoDB:**
   - Install and start MongoDB locally, or use MongoDB Atlas
   - No migrations needed - Mongoid creates collections automatically
   - Update `config/mongoid.yml` if using a remote MongoDB instance

4. **Encryption files:**
   
   - `app/javascript/encryption/xgnarly.mjs` contains a working implementation adapted from `encode.js` in the `tiktok-web-reverse-engineering` repo.
   - `app/javascript/encryption/xbogus.mjs` currently uses a **placeholder** implementation that generates a hash-based value.
   - In production you may want to replace `xbogus.mjs` with a proper X‑Bogus implementation; the function signature is:
     - `signBogus(queryString, bodyString, userAgent, timestamp)` → returns X‑Bogus string
   - X‑Gnarly signature:
     - `signGnarly(queryString, bodyString, userAgent, version, envcode)` → returns X‑Gnarly string

5. **Create a TikTokShop record (once):**
```ruby
# In Rails console (example)
shop = TikTokShop.create!(
  name: "My TikTok Shop",
  cookie: "_m4b_theme_=new; i18next=en; ...", # Your full cookie string
  oec_seller_id: "7496020242935155064",
  base_url: "https://seller-us.tiktok.com",
  fp: "verify_mikvoq3z_Aejdw0Hu_C50w_4kN9_92s6_MdfQONpspa58",
  timezone_offset: -28800,
  region: "US"
)

shop.id # <- Mongoid ObjectId, use this in all examples below
```

### Running the Scraper (Rails console)

```ruby
# In Rails console
shop = TikTokShop.first          # or find by name / oec_seller_id

SyncProductAnalytics.call(
  tik_tok_shop_id: shop.id,      # Mongoid ObjectId (NOT integer 1)
  start_date: "2025-11-01",
  end_date:   "2025-11-30"
)
```

This service will:
- Fetch products for each day in the date range
- Handle pagination automatically
- Upsert products and daily snapshots (idempotent - safe to re-run)

### API Usage

Start the Rails server:
```bash
bundle exec rails server
```

Then make requests:
```bash
# Replace SHOP_ID with the Mongoid ObjectId from your TikTokShop record

# Get all products in date range
curl "http://localhost:3000/api/v1/tik_tok_shops/SHOP_ID/product_analytics?start_date=2025-11-01&end_date=2025-11-30"

# Filter by minimum GMV (in dollars)
curl "http://localhost:3000/api/v1/tik_tok_shops/SHOP_ID/product_analytics?start_date=2025-11-01&end_date=2025-11-30&min_gmv=1000"
```

**Response format:**
```json
{
  "data": [
    {
      "external_id": "123",
      "title": "Product A",
      "status": "live",
      "image_url": "https://...",
      "gmv": 2450.10,
      "items_sold": 88,
      "orders_count": 70
    }
  ]
}
```

---

## Architecture

### Components

1. **Fetcher (Node.js)**: Makes authenticated requests to TikTok Shop API
2. **Ingestion Service (Rails)**: Processes and stores data in daily snapshots
3. **Query Service (Rails)**: Aggregates and filters snapshot data
4. **API Endpoint (Rails)**: Exposes filtered product analytics

### Data Flow

```
TikTok Shop API → Node.js Fetcher → Rails Ingestion Service → Database
                                                                    ↓
                                                          Query Service → API
```

---

## Tradeoffs & Design Decisions

- **Daily Snapshots**: Storing daily snapshots instead of aggregated totals allows for historical analysis and trend tracking
- **Idempotency**: Unique constraints on `(tik_tok_shop_product_id, snapshot_date)` prevent duplicates on re-runs
- **Separation of Concerns**: Fetcher, ingestion, and query services are separated for maintainability
- **Pagination**: Fetcher handles pagination automatically to retrieve all products

