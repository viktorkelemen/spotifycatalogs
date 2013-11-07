class AddCatalogIdToAlbums < ActiveRecord::Migration
  def change
    add_column :albums, :catalog_id, :integer
  end
end
