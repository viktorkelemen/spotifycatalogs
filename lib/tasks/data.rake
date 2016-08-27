require 'hallon'
require 'pry'
require 'nokogiri'
require 'open-uri'
require 'mojinizer'
require_relative 'spotira_utils.rb'
require_relative 'result_list.rb'
require_relative 'fetchers/residentadvisor.rb'
require_relative 'fetchers/ghostly.rb'
require_relative 'fetchers/experimedia.rb'
require_relative 'fetchers/igloo.rb'
require_relative 'fetchers/ambientexotica.rb'
require_relative 'fetchers/inverted_audio.rb'
require_relative 'fetchers/raster_noton.rb'
require_relative 'fetchers/xlr8r.rb'
require_relative 'fetchers/exclaim.rb'
require_relative 'fetchers/thequietus.rb'

def get_ameto(url)
  doc = Nokogiri::HTML(open(url))
  result = []

  doc.css('.itemarea a').each do |line|
    unless line.text.empty?
      artist, album = line.text.split(' / ')
      if artist && album
        unless artist.contains_kanji? || album.contains_kanji?
          album = album.sub(/(?<=\[).+?(?=\])/, "").gsub('[]','').strip
          artist = artist.strip
          album = album.romaji if album.contains_kana?
          artist = artist.romaji if artist.contains_kana?
          result.push "artist:\"#{ artist }\" album:\"#{ album }\""
        end
      end
    end
  end

  result
end

def fetch_ameto
  result = []
  result += get_ameto('http://shop.ameto.biz/?mode=cate&cbid=511547&csid=0&sort=n')
  result += get_ameto('http://shop.ameto.biz/?mode=cate&cbid=511546&csid=0&sort=n')
  result += get_ameto('http://shop.ameto.biz/?mode=cate&cbid=511549&csid=0&sort=n')

  SpotiraUtils.fetch(result, 'ameto_day')
end

def fetch_discogs_goa
  url = 'http://www.discogs.com/explore?sort=year_desc&style=Goa+Trance&decade=2010&decade=now'
  doc = Nokogiri::HTML(open(url))
  result = []

  doc.css('.itemarea a').each do |line|
    unless line.text.empty?
      artist, album = line.text.split(' / ')
      if artist && album
        unless artist.contains_kanji? || album.contains_kanji?
          album = album.sub(/(?<=\[).+?(?=\])/, "").gsub('[]','').strip
          artist = artist.strip
          album = album.romaji if album.contains_kana?
          artist = artist.romaji if artist.contains_kana?
          result.push "artist:\"#{ artist }\" album:\"#{ album }\""
        end
      end
    end
  end

  puts result

end


def fetch_fact_best_albums_2013
  url = "http://www.factmag.com/2013/12/09/the-50-best-albums-of-2013/"
  doc = Nokogiri::HTML(open(url))
  result = []

  doc.css('#cml-column-right .page-52.dark-gray.hidden').each do |block|
    target_p = block.css('p + p')
    lines = target_p.first.content.split(/\n/)
    lines.each do |line|
      artist, album = line.sub('-','–').gsub(/\(.*?\)/, "").split(' – ')
      artist = artist[4..-1]
      album = album.strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  SpotiraUtils.fetch(result, 'fact_best_albums_2013')
end

def get_ambientblog_net_links
  url = "http://www.ambientblog.net/blog/category/recommendations/"
  doc = Nokogiri::HTML(open(url))
  doc.css('.entry-title a').first(10).map { |link| link['href'] }
end

def fetch_ambientblog_net
  # result = ResultList.new
  get_ambientblog_net_links.each do |url|
    doc = Nokogiri::HTML(open(url))
    ids = doc.css('a[title~="Spotify"]').map do |link|
      /album\/(\S+\Z)/.match(link['href']).captures.first
    end
    puts ids
  end
  # doc = Nokogiri::HTML(open(url))
  # doc.css('.entry-title').first(10).each do |
end

def login
  # Kill main thread if any other thread dies.
  Thread.abort_on_exception = true

  # Init Spotify
  appkey_path = File.expand_path('./spotify_appkey.key')
  unless File.exists?(appkey_path)
    abort <<-ERROR
      Your Spotify application key could not be found at the path:
        #{appkey_path}

      You may download your application key from:
        https://developer.spotify.com/en/libspotify/application-key/
    ERROR
  end

  hallon_username = ENV.fetch("SPOTIFY_USERNAME") { prompt("Please enter your spotify username") }
  hallon_password = ENV.fetch("SPOTIFY_PASSWORD") { prompt("Please enter your spotify password", hide: true) }
  hallon_appkey = IO.read(appkey_path)

  if hallon_username.empty? or hallon_password.empty?
    abort <<-ERROR
      Sorry, you must supply both username and password for Hallon to be able to log in.
    ERROR
  end

  session = Hallon::Session.initialize(hallon_appkey) do
    on(:connection_error) do |error|
      puts "[LOG] Connection error"
      Hallon::Error.maybe_raise(error)
    end

    on(:offline_error) do |error|
      puts "[LOG] Offline error"
    end

    on(:logged_out) do
      abort "[FAIL] Logged out!"
    end
  end
  session.login!(hallon_username, hallon_password)
  puts "Successfully logged in!"
end

namespace :data do

  task ra: :environment do
    login
    year = ENV.fetch("YEAR", Date.today.year)
    month = ENV.fetch("MONTH", Date.today.month)
    SpotiraFetchers.fetch_residentadvisor(Date.new(year.to_i,month.to_i))
  end

  task ghostly: :environment do
    login
    SpotiraFetchers.fetch_ghostly
  end

  task experimedia_featured: :environment do
    login
    SpotiraFetchers.fetch_experimedia_featured
  end

  task experimedia_new: :environment do
    login
    SpotiraFetchers.fetch_experimedia_new
  end

  task ameto: :environment do
    login
    fetch_ameto
  end

  task discogs_goa: :environment do
    fetch_discogs_goa
  end

  task raster_noton: :environment do
    login
    SpotiraFetchers.fetch_raster_noton
  end

  task best_albums_2013: :environment do
    login
    fetch_fact_best_albums_2013
  end

  task inverted_audio: :environment do
    login
    page = ENV.fetch("PAGE", 1)
    SpotiraFetchers.fetch_inverted_audio(page)
  end

  task igloo: :environment do
    login
    SpotiraFetchers.fetch_igloo
  end

  task ambientexotica: :environment do
    login
    SpotiraFetchers.fetch_ambientexotica
  end

  task xlr8r: :environment do
    login
    SpotiraFetchers.fetch_xlr8r
  end

  task thequietus: :environment do
    login
    SpotiraFetchers.fetch_the_quietus
  end

  task exclaim: :environment do
    login
    SpotiraFetchers.fetch_exclaim
  end

  task ambientblog: :environment do
    fetch_ambientblog_net
  end
end
