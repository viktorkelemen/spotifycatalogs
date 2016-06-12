class ResultList
  attr_reader :query
  def initialize
    @query = []
  end

  def add(artist, album)
    @query.push "artist:\"#{ artist }\" album:\"#{ album }\""
  end
end
