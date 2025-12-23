# Real Testing Flow - Step by Step

This is a **practical, hands-on testing guide** that walks you through testing the entire system with real data.

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] MongoDB running (check: `mongod` or MongoDB service running)
- [ ] Node.js installed (`node --version` should work)
- [ ] Ruby and Rails installed (`ruby --version`, `rails --version`)
- [ ] Dependencies installed (`bundle install`, `npm install`)
- [ ] Valid TikTok Shop cookie (from your browser)
- [ ] Your `oec_seller_id` (from TikTok Seller Center)

---

## Phase 1: Environment Setup (5 minutes)

### Step 1.1: Refresh PATH (Windows PowerShell)

```powershell
cd "F:\tictok scraping"
.\refresh-path.ps1
```

**Verify:**
```powershell
ruby --version    # Should show Ruby 3.x
node --version    # Should show Node.js v20.x
bundle --version  # Should show Bundler version
```

### Step 1.2: Verify MongoDB Connection

```powershell
# Open Rails console
bundle exec rails console
```

In console:
```ruby
# Test MongoDB connection
Mongoid.default_client.database.name
# Should output: "tiktok_shop_scraper_development"
```

If error: Check `config/mongoid.yml` and ensure MongoDB is running.

---

## Phase 2: Get Your TikTok Credentials (10 minutes)

### Step 2.1: Get Your Cookie

1. **Open TikTok Seller Center**: https://seller-us.tiktok.com
2. **Log in** to your account
3. **Open Developer Tools** (F12)
4. **Go to Application tab** → Cookies → `https://seller-us.tiktok.com`
5. **Copy ALL cookies** - Select all, copy as string
   - Format: `cookie1=value1; cookie2=value2; ...`

### Step 2.2: Get Your oec_seller_id

1. **Still in Developer Tools** → **Network tab**
2. **Refresh the page** (F5)
3. **Find any API request** (filter by "Fetch/XHR")
4. **Click on a request** → Look at URL or Headers
5. **Find `oec_seller_id`** in the URL parameters
   - Example: `?oec_seller_id=7496020242935155064`

### Step 2.3: Get Your fp (Fingerprint)

1. **In Developer Tools** → **Application tab** → **Cookies**
2. **Find cookie named `s_v_web_id`**
3. **Copy its value** - This is your `fp`
   - Example: `verify_mikvoq3z_Aejdw0Hu_C50w_4kN9_92s6_MdfQONpspa58`

---

## Phase 3: Create TikTokShop Record (2 minutes)

### Step 3.1: Open Rails Console

```powershell
bundle exec rails console
```

### Step 3.2: Create Shop Record

```ruby
# Replace with YOUR actual values
shop = TikTokShop.create!(
  name: "My TikTok Shop",
  cookie: "YOUR_FULL_COOKIE_STRING_HERE",  # From Step 2.1
  oec_seller_id: "YOUR_OEC_SELLER_ID",      # From Step 2.2
  base_url: "https://seller-us.tiktok.com",
  fp: "YOUR_FP_VALUE",                      # From Step 2.3
  timezone_offset: -28800,                  # US Pacific Time
  region: "US"
)

# ⚠️ CRITICAL: Save this ID!
shop_id = shop.id
puts "✅ Shop created! ID: #{shop_id}"
puts "📝 Copy this ID: #{shop_id}"
```

**Expected Output:**
```
✅ Shop created! ID: 694a07b6a60081f7a9a1d6b3
📝 Copy this ID: 694a07b6a60081f7a9a1d6b3
```

**Save this ID** - You'll need it for all subsequent steps!

---

## Phase 4: Test Node.js Scraper (5 minutes)

### Step 4.1: Test with PowerShell

**Open a NEW PowerShell window** (keep Rails console open in the other):

```powershell
cd "F:\tictok scraping"
.\refresh-path.ps1

# Replace with YOUR values
$testData = @{
    cookie = "YOUR_FULL_COOKIE_STRING"
    oecSellerId = "YOUR_OEC_SELLER_ID"
    baseUrl = "https://seller-us.tiktok.com"
    fp = "YOUR_FP_VALUE"
    timezoneOffset = -28800
    startDate = "2025-12-17"  # Use a recent date
    endDate = "2025-12-18"
    pageNo = 0
    pageSize = 10
} | ConvertTo-Json

echo $testData | node app/javascript/products.mjs
```

### Step 4.2: Analyze Response

**✅ Success Response:**
```json
{
  "status_code": 0,
  "data": {
    "product_list": [...],
    "list_control": {...}
  }
}
```

**❌ Error Responses:**
- `status_code: -2` with `ETIMEDOUT` → Network issue
- `status_code: 10001` or similar → Authentication failed (cookie expired)
- `status_code: -1` → JSON parsing error

**If you see errors:**
- Network timeout: Check internet, firewall, proxy
- Authentication: Get fresh cookie from browser
- Other errors: Check the error message details

---

## Phase 5: Test Sync Service (10 minutes)

### Step 5.1: Test Single Day Sync

**In Rails console** (or new console):

```ruby
# Use the shop_id from Step 3.2
shop_id = "YOUR_SHOP_ID"  # e.g., "694a07b6a60081f7a9a1d6b3"

# Test sync for ONE day (recent date)
result = SyncProductAnalytics.call(
  tik_tok_shop_id: shop_id,
  start_date: "2025-12-17",  # Use a recent date
  end_date: "2025-12-17"
)

# Check results
puts "Success: #{result[:success]}"
puts "Errors: #{result[:errors].count}"

if result[:success]
  puts "✅ Sync successful!"
  puts "Products saved: #{TikTokShopProduct.count}"
  puts "Snapshots saved: #{TikTokShopProductSnapshot.count}"
else
  puts "❌ Sync had errors:"
  result[:errors].each { |e| puts "  - #{e}" }
end
```

### Step 5.2: Verify Data Was Saved

```ruby
# Check products
TikTokShopProduct.count
TikTokShopProduct.first

# Check snapshots
TikTokShopProductSnapshot.count
TikTokShopProductSnapshot.first

# Check specific product
product = TikTokShopProduct.first
puts "Product: #{product.title}"
puts "External ID: #{product.external_id}"
puts "Snapshots: #{product.tik_tok_shop_product_snapshots.count}"
```

**Expected:**
- At least 1 product saved
- At least 1 snapshot saved
- Product has title, external_id, etc.

### Step 5.3: Test Multi-Day Sync (Optional)

```ruby
# Sync last 7 days
result = SyncProductAnalytics.call(
  tik_tok_shop_id: shop_id,
  start_date: 7.days.ago.to_date.to_s,
  end_date: Date.today.to_s
)

puts "Success: #{result[:success]}"
puts "Total products: #{TikTokShopProduct.count}"
puts "Total snapshots: #{TikTokShopProductSnapshot.count}"
```

---

## Phase 6: Test Query Service (5 minutes)

### Step 6.1: Query Without Filter

**In Rails console:**

```ruby
shop_id = "YOUR_SHOP_ID"

# Query all products for a date range
results = ProductAnalyticsQuery.call(
  tik_tok_shop_id: shop_id,
  start_date: "2025-12-17",
  end_date: "2025-12-17"
)

puts "Found #{results.count} products"
results.first(3).each do |product|
  puts "  - #{product[:title]}: $#{product[:gmv]} (#{product[:items_sold]} items)"
end
```

**Expected Output:**
```
Found 15 products
  - Product Name 1: $1234.56 (45 items)
  - Product Name 2: $987.65 (32 items)
  ...
```

### Step 6.2: Query With GMV Filter

```ruby
# Only products with GMV >= $100
results = ProductAnalyticsQuery.call(
  tik_tok_shop_id: shop_id,
  start_date: "2025-12-17",
  end_date: "2025-12-17",
  min_gmv_cents: 10000  # $100 in cents
)

puts "Products with GMV >= $100: #{results.count}"
```

---

## Phase 7: Test API Endpoint (10 minutes)

### Step 7.1: Start Rails Server

**Open a NEW PowerShell window:**

```powershell
cd "F:\tictok scraping"
.\refresh-path.ps1
bundle exec rails server
```

**Wait for:** `Listening on tcp://localhost:3000`

### Step 7.2: Test API with curl

**Open ANOTHER PowerShell window:**

```powershell
# Replace YOUR_SHOP_ID with your actual shop ID
$shopId = "YOUR_SHOP_ID"

# Test basic query
curl "http://localhost:3000/api/v1/tik_tok_shops/$shopId/product_analytics?start_date=2025-12-17&end_date=2025-12-17"
```

**Expected Response:**
```json
{
  "data": [
    {
      "external_id": "123456",
      "title": "Product Name",
      "status": "live",
      "image_url": "https://...",
      "gmv": 1234.56,
      "items_sold": 45,
      "orders_count": 38
    }
  ]
}
```

### Step 7.3: Test API with GMV Filter

```powershell
# Only products with GMV >= $100
curl "http://localhost:3000/api/v1/tik_tok_shops/$shopId/product_analytics?start_date=2025-12-17&end_date=2025-12-17&min_gmv=100"
```

### Step 7.4: Test API in Browser

Open in browser:
```
http://localhost:3000/api/v1/tik_tok_shops/YOUR_SHOP_ID/product_analytics?start_date=2025-12-17&end_date=2025-12-17
```

**Expected:** JSON response displayed in browser

### Step 7.5: Test Error Handling

```powershell
# Missing required parameter (should return 400)
curl "http://localhost:3000/api/v1/tik_tok_shops/$shopId/product_analytics?start_date=2025-12-17"

# Invalid shop ID (should return 500 or 404)
curl "http://localhost:3000/api/v1/tik_tok_shops/invalid_id/product_analytics?start_date=2025-12-17&end_date=2025-12-17"
```

---

## Phase 8: Test Rake Task (5 minutes)

### Step 8.1: Test Rake Task

**In PowerShell:**

```powershell
cd "F:\tictok scraping"
.\refresh-path.ps1

# Replace YOUR_SHOP_ID with your actual shop ID
bundle exec rake tik_tok_shop:sync[YOUR_SHOP_ID,2025-12-17,2025-12-17]
```

**Expected Output:**
```
Syncing TikTok Shop YOUR_SHOP_ID from 2025-12-17 to 2025-12-17...
✓ Sync completed successfully
```

**Or if errors:**
```
✗ Sync completed with errors:
  - Failed to fetch page 0 for date 2025-12-17: request_failed
```

### Step 8.2: Test Date Range

```powershell
# Sync last 3 days
bundle exec rake tik_tok_shop:sync[YOUR_SHOP_ID,2025-12-15,2025-12-17]
```

---

## Phase 9: End-to-End Test (10 minutes)

### Step 9.1: Full Pipeline Test

1. **Clear existing data** (optional):
   ```ruby
   # In Rails console
   TikTokShopProductSnapshot.delete_all
   TikTokShopProduct.delete_all
   ```

2. **Sync data:**
   ```powershell
   bundle exec rake tik_tok_shop:sync[YOUR_SHOP_ID,2025-12-15,2025-12-17]
   ```

3. **Verify data:**
   ```ruby
   # In Rails console
   puts "Products: #{TikTokShopProduct.count}"
   puts "Snapshots: #{TikTokShopProductSnapshot.count}"
   ```

4. **Query via API:**
   ```powershell
   curl "http://localhost:3000/api/v1/tik_tok_shops/YOUR_SHOP_ID/product_analytics?start_date=2025-12-15&end_date=2025-12-17&min_gmv=500"
   ```

5. **Verify aggregation:**
   - Products should have aggregated metrics across all 3 days
   - GMV should be sum of all days
   - Items sold should be sum of all days

---

## Phase 10: Test Edge Cases (10 minutes)

### Step 10.1: Test Idempotency

```ruby
# Run sync twice - should not create duplicates
result1 = SyncProductAnalytics.call(
  tik_tok_shop_id: shop_id,
  start_date: "2025-12-17",
  end_date: "2025-12-17"
)

count_before = TikTokShopProductSnapshot.count

result2 = SyncProductAnalytics.call(
  tik_tok_shop_id: shop_id,
  start_date: "2025-12-17",
  end_date: "2025-12-17"
)

count_after = TikTokShopProductSnapshot.count

puts "Before: #{count_before}, After: #{count_after}"
puts "Should be equal (idempotent): #{count_before == count_after}"
```

**Expected:** Counts should be equal (no duplicates)

### Step 10.2: Test Empty Date Range

```ruby
# Date range with no data
result = SyncProductAnalytics.call(
  tik_tok_shop_id: shop_id,
  start_date: "2020-01-01",  # Very old date
  end_date: "2020-01-02"
)

puts "Success: #{result[:success]}"
puts "Errors: #{result[:errors]}"
```

**Expected:** Should complete successfully with no errors (just no data)

### Step 10.3: Test Invalid Shop ID

```ruby
# Should raise error
begin
  SyncProductAnalytics.call(
    tik_tok_shop_id: "invalid_id",
    start_date: "2025-12-17",
    end_date: "2025-12-17"
  )
rescue => e
  puts "✅ Correctly raised error: #{e.message}"
end
```

---

## Troubleshooting Common Issues

### Issue: "bundle is not recognized"
**Solution:** Run `.\refresh-path.ps1`

### Issue: "ETIMEDOUT" errors
**Solution:** 
- Check internet connection
- Check firewall/proxy settings
- Try again (might be temporary)

### Issue: Authentication errors (status_code: 10001)
**Solution:**
- Cookie expired - get fresh cookie from browser
- Verify `oec_seller_id` is correct
- Verify `fp` is correct

### Issue: "No products found"
**Solution:**
- Check date range has data in TikTok Shop
- Try a more recent date
- Verify your shop has products

### Issue: "MongoDB connection failed"
**Solution:**
- Ensure MongoDB is running
- Check `config/mongoid.yml`
- Verify MongoDB connection string

### Issue: "Shop not found"
**Solution:**
- Verify shop ID is correct: `TikTokShop.first.id`
- Use MongoDB ObjectId format (not integer)

---

## Success Criteria

✅ **All tests pass if:**
1. Node.js scraper returns `status_code: 0` with product data
2. Sync service saves products and snapshots to MongoDB
3. Query service returns aggregated product data
4. API endpoint returns JSON with product analytics
5. Rake task completes successfully
6. Idempotency works (re-running doesn't create duplicates)
7. Date range filtering works correctly
8. GMV filtering works correctly

---

## Next Steps After Testing

Once all tests pass:
1. Set up scheduled sync (cron job or scheduled task)
2. Monitor for errors in production
3. Consider implementing proper X-Bogus if needed
4. Add error alerting/monitoring
5. Scale up for multiple shops

---

## Quick Reference

**Get Shop ID:**
```ruby
TikTokShop.first.id
```

**Run Sync:**
```powershell
bundle exec rake tik_tok_shop:sync[SHOP_ID,START_DATE,END_DATE]
```

**Query API:**
```
http://localhost:3000/api/v1/tik_tok_shops/SHOP_ID/product_analytics?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&min_gmv=100
```

