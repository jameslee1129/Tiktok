namespace :tik_tok_shop do
  desc "Sync product analytics for a TikTok Shop"
  task :sync, [:shop_id, :start_date, :end_date] => :environment do |_t, args|
    shop_id = args[:shop_id] || ENV['SHOP_ID']
    start_date = args[:start_date] || ENV['START_DATE'] || 30.days.ago.to_date
    end_date = args[:end_date] || ENV['END_DATE'] || Date.today

    unless shop_id
      puts "Usage: rake tik_tok_shop:sync[shop_id,start_date,end_date]"
      puts "   or: SHOP_ID=1 START_DATE=2025-11-01 END_DATE=2025-11-30 rake tik_tok_shop:sync"
      exit 1
    end

    puts "Syncing TikTok Shop #{shop_id} from #{start_date} to #{end_date}..."
    
    result = SyncProductAnalytics.call(
      tik_tok_shop_id: shop_id.to_s,
      start_date: start_date.to_s,
      end_date: end_date.to_s
    )

    if result[:success]
      puts "✓ Sync completed successfully"
    else
      puts "✗ Sync completed with errors:"
      result[:errors].each { |error| puts "  - #{error}" }
    end
  end
end

