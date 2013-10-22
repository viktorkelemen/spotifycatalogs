class AddCoverUrlToAlbum < ActiveRecord::Migration
  def change
    add_column :albums, :cover_url, :string
  end
end
