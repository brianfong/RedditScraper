# require 'rails'
require 'shotgun'
require 'faraday'
require 'json'
require 'pry'
require 'net/https'
require 'open-uri'
require 'logger'
require 'sqlite3'

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

# TODO: Make this 100 objects
# TODO: Once you have this all in the database, you can then fetch with query params before_id/after_id depending on how you want to loop
response = conn.get 'https://www.reddit.com/r/memes/.json?limit=1'
parsed_json = JSON.parse(response.body.to_json)

# When in debug; write out the full thing; otherwise we'll skip it
logger.debug parsed_json

# Fields we want
# TODO: Do this better. Once you fetch 100, you will need to essentially do this in a "for loop"
name = JSON.parse(parsed_json)["data"]["children"][0]["data"]["name"]
title = JSON.parse(parsed_json)["data"]["children"][0]["data"]["title"]
author = JSON.parse(parsed_json)["data"]["children"][0]["data"]["author"]
url = JSON.parse(parsed_json)["data"]["children"][0]["data"]["url"]
permalink = JSON.parse(parsed_json)["data"]["children"][0]["data"]["permalink"]

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
db.execute("INSERT INTO posts (name, author, title, url, permalink) 
            VALUES (?, ?, ?, ?, ?)", [name, title, author, url, permalink])

# TODO: Fetch the image, store in ./tmp/
logger.warn "Downloading #{url}"
img = conn.get "#{url}"
File.open("tmp/#{name}.jpg", 'wb') { |fp| fp.write(img.body) }

# TODO: Use ImageMagick to normalize the file formats/color depth and all that jazz
# https://github.com/minimagick/minimagick