require 'hallon'
require 'pry'
require 'nokogiri'
require 'open-uri'


def fetch(date)
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

  result.each do |query|
    search = Hallon::Search.new(query)

    puts query
    search.load

    album = search.albums.first
    params = {}
    if album

      json = JSON.parse(open("https://embed.spotify.com/oembed/?url=#{ album.to_str }").read)
      thumbnail = json["thumbnail_url"].sub('/cover/','/300/')
      params = {
        spotify_url: album.to_str,
        title: album.name,
        artist: album.artist.name,
        image: thumbnail,
        date: date
      }

      unless Album.exists?({ title: params[:title], artist: params[:artist] })
        Album.new(params).save!
        puts params
      end
    end
  end
end


namespace :data do

  desc "Fetch RA latest reviews"
  task ra: :environment do

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

    fetch(Date.new(2013,4))
    fetch(Date.new(2013,5))
    fetch(Date.new(2013,6))
    fetch(Date.new(2013,7))
    fetch(Date.new(2013,8))
    fetch(Date.new(2013,9))
    fetch(Date.new(2013,10))

  end
end
