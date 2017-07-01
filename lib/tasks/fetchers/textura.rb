require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'
require_relative '../result_list'

module SpotiraFetchers

  def self.fetch_textura
    url = 'http://textura.org/pages/reviews.htm'
    doc = Nokogiri::HTML(open(url))
    result = ResultList.new
    doc.xpath('//a[contains(@href,"../archives")]/strong').each do |link|
      artist = link.at_xpath('text()')
      album = link.at_xpath('em/text()')
      if artist && album
        artist = artist.text.sub(/:\s*$/,'').strip
        album = album.text.strip
        result.add(artist, album)
      end
    end
    SpotiraUtils.fetch(result.query, 'textura')
  end
end
