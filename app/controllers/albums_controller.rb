class AlbumsController < ApplicationController
  def index
    @albums = Album.first(100)
  end
end
