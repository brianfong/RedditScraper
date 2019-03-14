# require 'rails'
require 'shotgun'
require 'faraday'
require 'json'
require 'pry'
require 'net/https'
require 'open-uri'
require 'logger'
require 'sqlite3'
require 'uri'
require 'fileutils'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

def user_agent
  "Reddit::Scraper v0.0.1 (https://github.com/brianfong/RedditScraper)"
end

db = SQLite3::Database.new "test.db"

rows = db.execute <<-SQL
create table if not exists posts (
  name varchar(30),
  author text,
  title text,
  url text,
   permalink
 );
SQL

Faraday.default_connection = Faraday.new(options = {:headers=>{:user_agent => user_agent }})

conn = Faraday.default_connection

# TODO: Once you have this all in the database, you can then fetch with query params before_id/after_id depending on how you want to loop
response = conn.get 'https://www.reddit.com/r/memes/.json?limit=100'
parsed_json = JSON.parse(response.body.to_json)

# When in debug; write out the full thing; otherwise we'll skip it
logger.debug parsed_json

# # INSTEAD: 
# # https://stackoverflow.com/questions/22132623/ruby-iterate-over-parsed-json
# # https://stackoverflow.com/questions/44481167/parsing-api-with-httparty-nomethoderror-undefined-method-each-for-nilnilclas
#JSON.parse(parsed_json['data']['children']).each do |child|
JSON.parse(parsed_json)['data']['children'].each do |child|
  name      = child['data']['name']
  title     = child['data']['title']
  author    = child['data']['author']
  url       = child['data']['url']
  permalink = child['data']['permalink']

  # binding.pry

  # Think if you want to write better logging
  logger.warn "Found a meme: #{name}"
  logger.info title
  logger.info author
  logger.info url
  logger.info permalink

  # TODO: Move to rails legit; refer to the blog homework
  #       Write some migrations, use ActiveRecord.
  # TODO: Does this post already exist? Skip if it does
  # TODO: Add an "ID" column, set as uuid or integer. If you use uuid, you will also need a column of created_at.

  #Does dupe check work?
  def existsCheck(permalink)
    temp = db.execute( "select 1 where exists(
        select 1
        from permalink
        where promoID = ?
    ) ", [permalink] ).any?
  end

  db.execute("INSERT INTO posts (name, author, title, url, permalink) 
              VALUES (?, ?, ?, ?, ?)", [name, title, author, url, permalink])

  # TODO: Fetch the image, store in ./tmp/
  logger.warn "Downloading #{url}"
      
  img = conn.get "#{url}"
  FileUtils.mkdir_p 'tmp'
  File.open("tmp/#{name}.jpg", 'wb') { |fp| fp.write(img.body) }

  # TODO: Use ImageMagick to normalize the file formats/color depth and all that jazz
  # https://github.com/minimagick/minimagick

end
