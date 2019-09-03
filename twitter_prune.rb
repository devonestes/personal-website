require 'bundler'
require 'bundler/inline'

Bundler.settings.instance_variable_set(:@local_config, {})
Bundler.settings.instance_variable_set(:@global_config, {})

gemfile do
  source 'https://rubygems.org'
  gem 'unf_ext', '0.0.7.5'
  gem 'twitter', '6.2.0'
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["CONSUMER_KEY"]
  config.consumer_secret     = ENV["CONSUMER_SECRET"]
  config.access_token        = ENV["ACCESS_TOKEN"]
  config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
end

def collect_with_max_id(collection=[], max_id=nil, &block)
  response = yield(max_id)
  collection += response
  response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
end

def client.get_all_tweets(user)
  collect_with_max_id do |max_id|
    options = {count: 200, include_rts: true}
    options[:max_id] = max_id unless max_id.nil?
    user_timeline(user, options)
  end
end

one_week_ago = (Time.now - 60 * 60 * 24 * 7)

all_tweets = client.get_all_tweets("devoncestes")

tweets_to_delete = all_tweets.select do |tweet|
  tweet.created_at < one_week_ago
end

client.destroy_status(tweets_to_delete)
