require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'

module SpotiraFetchers

  def self.fetch_ambientexotica
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

    SpotiraUtils.fetch(result, 'ambientexotica')
  end

end
