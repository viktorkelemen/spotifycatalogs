require 'hallon'
require 'pry'
require 'nokogiri'
require 'open-uri'
require 'mojinizer'


def fetch(result, catalog_name)

  catalog = Catalog.find_by_name(catalog_name)
  unless catalog
    catalog = Catalog.new({ name: catalog_name })
    catalog.save!
  end

  result.each do |query|
    search = Hallon::Search.new(query)

    puts query
    search.load

    album = search.albums.first
    params = {}
    if album
      begin
        json = JSON.parse(open("https://embed.spotify.com/oembed/?url=#{ album.to_str }", "User-Agent" => "Ruby/#{RUBY_VERSION}").read)
        thumbnail = json["thumbnail_url"].sub('/cover/','/300/')
      rescue
        thumbnail = ''
      end

      params = {
        spotify_url: album.to_str,
        title: album.name,
        artist: album.artist.name,
        image: thumbnail
      }

      unless Album.exists?({ title: params[:title], artist: params[:artist] })
        catalog.albums.create(params)
        puts params
      end
    end
  end
end

def fetch_ra(date)
  url = "http://www.residentadvisor.net/reviews.aspx?format=album&yr=#{ date.year }&mn=#{ date.month }"

  doc = Nokogiri::HTML(open(url))

  result = []
  doc.css('.reviewArchive article h1').each do |link|
    artist, album = link.text.split(' - ')
    if artist && album
      artist = artist.strip
      album = album.strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'residentadvisor')
end


def fetch_textura
  url = 'http://textura.org/pages/reviews.htm'
  doc = Nokogiri::HTML(open(url))
  result = []

  doc.xpath('//a[contains(@href,"../")]').each do |link|
    artist = link.at_xpath('text()[1]')
    album = link.at_xpath('em')
    if artist && album
      artist = artist.text.sub(/:\s*$/,'').strip
      album = album.text.strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'textura')
end

def fetch_textura_top
  url = 'http://textura.org/reviews/2013top10s.htm'
  doc = Nokogiri::HTML(open(url))
  result = []

  doc.css('p.bodytext a[href*="../archives"]').each do |link|
    artist = link.at_xpath('text()[1]')
    album = link.at_xpath('em')
    if artist && album
      artist = artist.text.sub(/:\s*$/,'').strip
      album = album.text.strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'textura_top')
end



def fetch_experimedia_featured
  url = 'http://experimedia.net/index.php?main_page=featured_products'
  doc = Nokogiri::HTML(open(url))
  result = []

  doc.css('#featuredDefault table td.main strong').each do |line|
    artist, album = line.text.gsub(/\(.*?\)/, "").split(' - ')
    album = album.strip
    artist = artist.strip
    if artist && album
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'experimedia_featured')
end

def fetch_experimedia_new
  result = []

  [1,2,3,4,5,6,7,8,9,10].each do |page|
    url = "http://experimedia.net/index.php?main_page=products_new&disp_order=6&page=#{ page }"
      doc = Nokogiri::HTML(open(url))

    doc.css('#newProductsDefault table td.main strong').each do |line|
      artist, album = line.text.gsub(/\(.*?\)/, "").split(' - ')
      if artist && album
        album = album.strip
        artist = artist.strip
        result.push "artist:\"#{ artist }\" album:\"#{ album }\""
      end
    end
  end

  fetch(result, 'experimedia_new')
end

def fetch_igloo
  url = "http://igloomag.com/category/reviews"

  doc = Nokogiri::HTML(open(url))

  result = []
  doc.css('#content .post h2 a').each do |link|
    artist, album = link.text.split(' :: ')
    if artist && album
      artist = artist.strip
      album = album.gsub(/\([^)]+\)/, "").strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'igloomag')
end

def fetch_ambientexotica
  url = "http://www.ambientexotica.com/ambient-reviews"

  doc = Nokogiri::HTML(open(url))

  result = []
  doc.css('#content h4 a').each do |link|
    artist, album = link.text.split(' – ')
    if artist && album
      artist = artist.strip
      album = album.gsub(/\([^)]+\)/, "").gsub(/\A\p{Space}*|\p{Space}*\z/, '')
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'ambientexotica')
end

def fetch_xlr8r

  result = []

  (0..3).each do |page|
    url = "http://www.xlr8r.com/reviews/page/#{ page }"
    doc = Nokogiri::HTML(open(url))

    doc.css('.vw-post-box-post-title a').each do |post|
      artist = post.at_xpath('text()[1]')
      album = post.at_xpath('i')
      if artist && album
        artist = artist.text.sub(/:\s*$/,'').strip
        album = album.text.strip
        result.push "artist:\"#{ artist }\" album:\"#{ album }\""
      end
    end
  end

  fetch(result, 'xlr8r')
end


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

  fetch(result, 'ameto_day')
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


def fetch_raster_noton
  url = 'http://www.raster-noton.net/releases.php'
  doc = Nokogiri::HTML(open(url))
  result = []

  doc.css('h3 a').each do |link|
    code, artist, album = link.content.split(' | ')
    if artist && album
      artist = artist.sub(/:\s*$/,'').strip
      album = album.strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'rasternoton')
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

  fetch(result, 'fact_best_albums_2013')
end

def fetch_inverted_audio(page)
  result = []

  url = "http://inverted-audio.com/reviews"
  doc = Nokogiri::HTML(open("#{ url }/page/#{ page }"))

  doc.css('.the_content.post .ia-post-list-info').each do |link|
    artist, album = link.text.split(': ')
    if artist && album
      artist = artist.sub(/:\s*$/,'').strip
      album = album.strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'inverted_audio')
end

def fetch_the_quietus

  result = []
  (1..3).each do |page|
    url = "http://thequietus.com/reviews?page=#{ page }"
    doc = Nokogiri::HTML(open(url))

    doc.css('.review, .review_small').each do |review|
      artist = review.css('h4').at_xpath('text()[1]')
      album = review.css('.sub')
      if artist && album
        artist = artist.text.strip
        album = album.text.strip
        result.push "artist:\"#{ artist }\" album:\"#{ album }\""
      end
    end
  end

  fetch(result, 'the_quietus')
end

def fetch_exclaim
  result = ResultList.new
  url = "http://exclaim.ca/music/reviews/album_improv-avant-garde_dance-electronic"
  doc = Nokogiri::HTML(open(url))
  doc.css('.streamSingle-item').each do |review|
    artist = review.css('.streamSingle-item-title')
    album = review.css('.streamSingle-item-details')
    if artist && album
      result.add(
        artist.text.strip,
        album.text.strip,
      )
    end
  end
  fetch(result.query, 'exclaim')
end

class ResultList
  attr_reader :query
  def initialize
    @query = []
  end

  def add(artist, album)
    @query.push "artist:\"#{ artist }\" album:\"#{ album }\""
  end
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

  desc "Fetch RA latest reviews"
  task ra: :environment do
    login
    year = ENV.fetch("YEAR")
    month = ENV.fetch("MONTH")
    if year && month
      fetch_ra(Date.new(year.to_i,month.to_i))
    end
  end

  task textura: :environment do
    login
    fetch_textura
  end

  task textura_top: :environment do
    login
    fetch_textura_top
  end

  task experimedia_featured: :environment do
    login
    fetch_experimedia_featured
  end

  task experimedia_new: :environment do
    login
    fetch_experimedia_new
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
    fetch_raster_noton
  end

  task best_albums_2013: :environment do
    login
    fetch_fact_best_albums_2013
  end

  task inverted_audio: :environment do
    login
    page = ENV.fetch("PAGE")
    fetch_inverted_audio(page || 1)
  end

  task igloo: :environment do
    login
    fetch_igloo
  end

  task ambientexotica: :environment do
    login
    fetch_ambientexotica
  end

  task xlr8r: :environment do
    login
    fetch_xlr8r
  end

  task thequietus: :environment do
    login
    fetch_the_quietus
  end

  task exclaim: :environment do
    #login
    fetch_exclaim
  end

end
