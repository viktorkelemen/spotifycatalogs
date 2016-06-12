require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'

module SpotiraFetchers

  def self.fetch_igloo
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

    SpotiraUtils.fetch(result, 'igloomag')
  end

end
