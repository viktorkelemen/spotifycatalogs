class AddDateToAlbum < ActiveRecord::Migration
  def change
    add_column :albums, :date, :datetime
  end
end
