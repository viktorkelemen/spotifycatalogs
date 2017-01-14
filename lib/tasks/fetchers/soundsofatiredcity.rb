require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'

module SpotiraFetchers

  def self.fetch_soundsofatiredcity
    result = ResultList.new
    ['part-1','part-2','part-3','part-4','final-part'].each do |page|
      url = "http://soundsofatiredcity.com/best-of-2016-#{ page }"
      doc = Nokogiri::HTML(open(url))
      doc.css('.post_content h1 span').each do |link|
        artist, album = link.text.split(': ')
        artist = artist.split('.')[1]
        if artist && album
          artist = artist.strip
          album = album.gsub(/(?<=\[)[^\]]+?(?=\])/, "").gsub("[]","")
          album = album.strip
          result.add(artist, album)
        end
      end
    end

    SpotiraUtils.fetch(result.query, 'soundsofatiredcity')
  end

end
