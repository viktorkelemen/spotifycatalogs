require 'hallon'
require 'pry'
require 'nokogiri'
require 'open-uri'
require 'mojinizer'


def fetch(result, catalog_name, date = nil)

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
        json =  JSON.parse(open("https://embed.spotify.com/oembed/?url=#{ album.to_str }").read)
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
      if date
        params[:date] = date
      end

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
  doc.xpath('//a[@class="music" and contains(@href,"/review-view")]').each do |link|
    artist, album = link.text.split(' - ')
    if artist && album
      artist = artist.strip
      album = album.strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'residentadvisor', date)
end


def fetch_textura
  url = 'http://textura.org/pages/reviews.htm'
  doc = Nokogiri::HTML(open(url))
  result = []

  date = DateTime.parse(doc.xpath("//p[@class='style9'][1]").text)

  doc.xpath('//a[contains(@href,"../")]').each do |link|
    artist = link.at_xpath('text()[1]')
    album = link.at_xpath('em')
    if artist && album
      artist = artist.text.sub(/:\s*$/,'').strip
      album = album.text.strip
      result.push "artist:\"#{ artist }\" album:\"#{ album }\""
    end
  end

  fetch(result, 'textura', date)
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
      album = album.strip
      artist = artist.strip
      if artist && album
        result.push "artist:\"#{ artist }\" album:\"#{ album }\""
      end
    end
  end

  fetch(result, 'experimedia_new')
end

def fetch_ameto_day
  url = 'http://shop.ameto.biz/?mode=cate&cbid=511547&csid=0&sort=n'
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

  fetch(result, 'ameto_day')
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

  task experimedia_featured: :environment do
    login
    fetch_experimedia_featured
  end

  task experimedia_new: :environment do
    login
    fetch_experimedia_new
  end

  task ameto_day: :environment do
    login
    fetch_ameto_day
  end
end
