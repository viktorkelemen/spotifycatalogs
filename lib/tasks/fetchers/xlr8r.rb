require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'
require_relative '../result_list'

module SpotiraFetchers

  def self.fetch_xlr8r
    result = ResultList.new
    (1..4).each do |page|
      url = "https://www.xlr8r.com/reviews/page/#{ page }/"
      doc = Nokogiri::HTML(open(url))
      doc.css('.vw-post-box-post-title a').each do |post|
        artist = post.at_xpath('text()[1]')
        album = post.at_xpath('i')
        if artist && album
          artist = artist.text.sub(/:\s*$/,'').strip
          album = album.text.strip
          result.add(artist, album)
        end
      end
    end

    SpotiraUtils.fetch(result.query, 'xlr8r')
  end
end
