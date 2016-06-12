require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'

module SpotiraFetchers

  def self.fetch_residentadvisor(date)
    url = "https://www.residentadvisor.net/reviews.aspx?format=album&yr=#{ date.year }&mn=#{ date.month }"

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

    SpotiraUtils.fetch(result, 'residentadvisor')
  end

end
