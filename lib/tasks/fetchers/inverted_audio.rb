require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'

module SpotiraFetchers

  def self.fetch_inverted_audio(page)
    result = []

    url = "http://inverted-audio.com/reviews"
    doc = Nokogiri::HTML(open("#{ url }/page/#{ page }"))

    doc.css('.the_content.post .ia-post-list-info').each do |link|
      artist, album = link.text.split(': ')
      if artist && album
        artist = artist.sub(/:\s*$/,'').strip
        album = album.strip
        result.push "artist:\"#{ artist }\" album:\"#{ album }\""
      end
    end

    SpotiraUtils.fetch(result, 'inverted_audio')
  end

end
