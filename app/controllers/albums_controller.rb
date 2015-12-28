class AlbumsController < ApplicationController
  def index
    @albums = Album.first(1000)
  end
end
