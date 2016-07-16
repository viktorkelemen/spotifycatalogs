require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'
require_relative '../result_list'

module SpotiraFetchers

  def self.fetch_raster_noton
    result = ResultList.new
    url = 'http://www.raster-noton.net/releases/'
    doc = Nokogiri::HTML(open(url))

    doc.css('#shop-listing .artbox').each do |link|
      artist = link.css('.supplier_name')
      album = link.css('.artikel_name')
      if artist && album
        artist = artist.text.strip
        album = album.text.strip
        result.add(artist, album)
      end
    end
    SpotiraUtils.fetch(result.query, 'rasternoton')
  end

end
