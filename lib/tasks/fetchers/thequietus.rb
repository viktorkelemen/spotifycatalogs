require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'
require_relative '../result_list'

module SpotiraFetchers

  def self.fetch_the_quietus
    result = ResultList.new
    (1..3).each do |page|
      url = "http://thequietus.com/reviews?page=#{ page }"
      doc = Nokogiri::HTML(open(url))

      doc.css('.review, .review_small').each do |review|
        artist = review.css('h4').at_xpath('text()[1]')
        album = review.css('.sub')
        if artist && album
          artist = artist.text.strip
          album = album.text.strip
          result.add(artist, album)
        end
      end
    end

    SpotiraUtils.fetch(result.query, 'the_quietus')
  end
end
