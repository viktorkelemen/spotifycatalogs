class RenameCoverUrlToImageInAlbums < ActiveRecord::Migration
  def change
    rename_column :albums, :cover_url, :image
  end
end
