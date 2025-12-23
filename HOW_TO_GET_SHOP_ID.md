# How to Get Your Shop ID

There are **two types of IDs** you need to know about:

1. **MongoDB `_id`** (for sync/API calls) - Auto-generated when you create a TikTokShop record
2. **`oec_seller_id`** (TikTok's seller ID) - From your TikTok Shop account

---

## Getting the MongoDB Shop ID (for sync/API)

### Method 1: When Creating a New Shop

When you create a TikTokShop record, save the ID immediately:

```ruby
# In Rails console
shop = TikTokShop.create!(
  name: "My TikTok Shop",
  cookie: "your_cookie_string",
  oec_seller_id: "7496020242935155064",
  base_url: "https://seller-us.tiktok.com",
  fp: "verify_mikvoq3z_Aejdw0Hu_C50w_4kN9_92s6_MdfQONpspa58",
  timezone_offset: -28800,
  region: "US"
)

# Get the ID immediately
puts "Shop ID: #{shop.id}"
# Example output: Shop ID: 694a07b6a60081f7a9a1d6b3
```

### Method 2: Find Existing Shop(s)

```ruby
# In Rails console
bundle exec rails console

# List all shops with their IDs
TikTokShop.all.each do |shop|
  puts "ID: #{shop.id} | Name: #{shop.name} | oec_seller_id: #{shop.oec_seller_id}"
end

# Or get the first shop
shop = TikTokShop.first
puts "Shop ID: #{shop.id}"

# Or find by name
shop = TikTokShop.where(name: "My TikTok Shop").first
puts "Shop ID: #{shop.id}" if shop

# Or find by oec_seller_id
shop = TikTokShop.where(oec_seller_id: "7496020242935155064").first
puts "Shop ID: #{shop.id}" if shop
```

### Method 3: Quick One-Liner

```ruby
# Get ID of first shop
TikTokShop.first&.id

# Get all shop IDs
TikTokShop.pluck(:id)
```

---

## Getting the TikTok `oec_seller_id` (if you don't have it)

The `oec_seller_id` is TikTok's seller ID. Here's how to find it:

### Method 1: From Your Browser (Easiest)

1. **Log into TikTok Seller Center**: https://seller-us.tiktok.com
2. **Open Developer Tools** (F12)
3. **Go to Network tab**
4. **Refresh the page** or navigate to any page
5. **Look for API requests** - the `oec_seller_id` appears in:
   - URL parameters: `?oec_seller_id=7496020242935155064`
   - Request headers
   - Cookie values (sometimes in `global_seller_id_unified_seller_env`)

### Method 2: From Your Cookie

The `oec_seller_id` might be in your cookie string. Look for:
- `global_seller_id_unified_seller_env=7496020242935155064`
- `oec_seller_id_unified_seller_env=7496020242935155064`

### Method 3: From Browser Console

1. **Open TikTok Seller Center** in your browser
2. **Open Console** (F12 → Console tab)
3. **Run this JavaScript**:
   ```javascript
   // Try to find seller ID in various places
   console.log('Cookies:', document.cookie);
   
   // Check localStorage
   console.log('LocalStorage:', {...localStorage});
   
   // Check sessionStorage
   console.log('SessionStorage:', {...sessionStorage});
   ```

### Method 4: From Network Requests

1. **Open Developer Tools** (F12)
2. **Go to Network tab**
3. **Filter by "Fetch/XHR"**
4. **Click on any API request**
5. **Look at the Request URL** - it will contain `oec_seller_id=...`

Example URL:
```
https://seller-us.tiktok.com/api/v2/insights/seller/ttp/product/list/v2?oec_seller_id=7496020242935155064&...
```

---

## Complete Example: Creating and Using Shop ID

```ruby
# Step 1: Open Rails console
bundle exec rails console

# Step 2: Create shop (replace with your actual values)
shop = TikTokShop.create!(
  name: "My TikTok Shop",
  cookie: "your_full_cookie_string_here",
  oec_seller_id: "7496020242935155064",  # From TikTok
  base_url: "https://seller-us.tiktok.com",
  fp: "verify_mikvoq3z_Aejdw0Hu_C50w_4kN9_92s6_MdfQONpspa58",  # From your cookie
  timezone_offset: -28800,
  region: "US"
)

# Step 3: Save the ID
shop_id = shop.id
puts "✅ Shop created! ID: #{shop_id}"

# Step 4: Use it for sync
SyncProductAnalytics.call(
  tik_tok_shop_id: shop_id,
  start_date: "2025-12-17",
  end_date: "2025-12-17"
)

# Step 5: Use it for API
# URL: http://localhost:3000/api/v1/tik_tok_shops/#{shop_id}/product_analytics?start_date=2025-12-17&end_date=2025-12-17
```

---

## Quick Reference Commands

```ruby
# List all shops
TikTokShop.all.map { |s| { id: s.id, name: s.name, oec_seller_id: s.oec_seller_id } }

# Get first shop ID
TikTokShop.first&.id

# Count shops
TikTokShop.count

# Find shop by oec_seller_id
TikTokShop.where(oec_seller_id: "7496020242935155064").first&.id
```

---

## Troubleshooting

### "Shop not found" error
- Make sure you're using the MongoDB `_id` (not `oec_seller_id`)
- Verify the shop exists: `TikTokShop.find("your_id")`

### "Multiple shops found"
- If you have multiple shops, be specific:
  ```ruby
  shop = TikTokShop.where(name: "Specific Shop Name").first
  shop_id = shop.id
  ```

### "Don't know my oec_seller_id"
- Follow Method 1 above (from browser network requests)
- It's usually a long number like `7496020242935155064`

