require 'rails'
require 'shotgun'
require 'faraday'
require 'json'
require 'pry'
require 'net/https'
require 'open-uri'

Faraday.default_connection = Faraday.new(options = {:headers=>{:user_agent=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112 Safari/534.30"}})

# conn = Faraday.new(:url => 'https://www.reddit.com/r/memes.json') do |faraday|
#   faraday.request  :url_encoded
#   faraday.response :logger
#   faraday.adapter  Faraday.default_adapter
# end

#  response = conn.get '/r/memes.json'
#  response.body

# parsed_json = JSON.parse(response.body)
# puts result

# OR
result = JSON.parse(open("https://old.reddit.com/r/memes/.json?limit=10").read)
result.each do |key, value|
   puts "result[#{key}] = #{value}"
 end
