require 'hallon'
require 'pry'
require 'nokogiri'
require 'open-uri'
require 'mojinizer'

module SpotiraUtils

  def self.fetch(result, catalog_name)

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
        params = {
          spotify_url: album.to_str,
          title: album.name,
          artist: album.artist.name,
          image: self.get_thumbnail(album)
        }

        unless Album.exists?({ title: params[:title], artist: params[:artist] })
          catalog.albums.create(params)
          puts params
        end
      end
    end
  end

  def self.get_thumbnail(album)
    begin
      json = JSON.parse(open("https://embed.spotify.com/oembed/?url=#{ album.to_str }", "User-Agent" => "Ruby/#{RUBY_VERSION}").read)
      json["thumbnail_url"].sub('/cover/','/300/')
    rescue
      ''
    end
  end

end
