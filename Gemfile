source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.0'

gem 'rails', '~> 7.0'
gem 'mongoid', '~> 8.0'
gem 'puma', '~> 6.0'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '~> 3.3'
end

# Windows-specific timezone data
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

