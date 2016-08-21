require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'

module SpotiraFetchers

  def self.fetch_exclaim
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
    SpotiraUtils.fetch(result.query, 'exclaim')
  end

end
