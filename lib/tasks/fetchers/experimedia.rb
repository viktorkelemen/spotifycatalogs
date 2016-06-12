require 'nokogiri'
require 'open-uri'
require_relative '../spotira_utils.rb'
require_relative '../result_list'

module SpotiraFetchers

  def self.fetch_experimedia_featured
    result = ResultList.new
    url = 'http://experimedia.net/index.php?main_page=featured_products'
    doc = Nokogiri::HTML(open(url))

    doc.css('#featuredDefault table td.main strong').each do |line|
      artist, album = line.text.gsub(/\(.*?\)/, "").split(' - ')
      album = album.strip
      artist = artist.strip
      if artist && album
        result.add(artist, album)
      end
    end

    SpotiraUtils.fetch(result.query, 'experimedia_featured')
  end

  def self.fetch_experimedia_new
    result = ResultList.new
    [1,2,3,4,5,6,7,8,9,10].each do |page|
      url = "http://experimedia.net/index.php?main_page=products_new&disp_order=6&page=#{ page }"
        doc = Nokogiri::HTML(open(url))

      doc.css('#newProductsDefault table td.main strong').each do |line|
        artist, album = line.text.gsub(/\(.*?\)/, "").split(' - ')
        if artist && album
          album = album.strip
          artist = artist.strip
          result.add(artist, album)
        end
      end
    end

    SpotiraUtils.fetch(result.query, 'experimedia_new')
  end

end
