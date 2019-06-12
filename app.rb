require 'pg'
require 'shotgun'
require 'faraday'
require 'json'
require 'pry'
require 'net/https'
require 'open-uri'
require 'logger'
require 'uri'
require 'fileutils'
require 'mini_magick'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

def user_agent
  "Reddit::Scraper v0.0.4 (https://github.com/brianfong/RedditScraper)"
end

conn = PG.connect.new(dbname: 'development.pg')
  # Ensures the table is created if it doesn't exist
  conn.exec("CREATE TABLE IF NOT EXISTS memes (
    name varchar, 
    author text,
    title text,
    url text,
    permalnk text
    );")
  res.result_status
rescue PG::Error => pg_error
  puts "Table creation failed: #{pg_error.message}"
end


# db = SQLite3::Database.new "test.db"

# rows = db.execute <<-SQL
# create table if not exists posts (
#   name varchar(30),
#   author text,
#   title text,
#   url text,
#   permalink text
#  );
#=SQL

rows = db.execute <<-SQL
create unique index if not exists name_posts on posts(name);
SQL

Faraday.default_connection = Faraday.new(options = {:headers=>{:user_agent => user_agent }})

conn = Faraday.default_connection

# TODO: Once you have this all in the database, you can then fetch with query params before_id/after_id depending on how you want to loop
response = conn.get 'https://www.reddit.com/r/memes/.json?limit=10'
parsed_json = JSON.parse(response.body.to_json)

# When in debug; write out the full thing; otherwise we'll skip it
logger.debug parsed_json

JSON.parse(parsed_json)['data']['children'].each do |child|
  name      = child['data']['name']
  title     = child['data']['title']
  author    = child['data']['author']
  url       = child['data']['url']
  permalink = child['data']['permalink']

  #binding.pry

  #       Write some migrations, use ActiveRecord.  
  def existsCheck(permalink)
    temp = db.execute( "SELECT 1 where exists(
        SELECT permalink
        FROM test.db
        WHERE permalink = ?
    ) ", [permalink] ).any?

    exit if existsCheck(permalink) != 0

  end

  FileUtils.mkdir_p 'tmp'

  begin
    db.execute("INSERT INTO posts (name, author, title, url, permalink) VALUES (?, ?, ?, ?, ?)", [name, author, title, url, permalink])
    logger.info "Inserted: #{name}"
    logger.warn "Downloading #{url}"

    image = MiniMagick::Image.open("#{url}")
    # binding.pry
    logger.info "Exif: #{image.exif}"
    image.resize "500x500"
    image.format "png"
    image.write "./tmp/#{name}.png"

  rescue
    logger.info "Skipping insert: #{name}"
  end
end