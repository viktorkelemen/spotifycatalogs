require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'

module SpotiraFetchers

  def self.fetch_ghostly
    result = ResultList.new
    url = 'http://ghostly.com/releases'
    doc = Nokogiri::HTML(open(url))
    doc.css('.artist-releases').each do |link|
      artist = link.css('.artist')
      album = link.css('.title')
      if artist && album
        result.add(
          artist.text.strip,
          album.text.strip,
        )
      end
    end

    SpotiraUtils.fetch(result.query, 'ghostly')
  end

end
