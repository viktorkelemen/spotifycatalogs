class AddImageToCatalogs < ActiveRecord::Migration
  def change
    add_column :catalogs, :image, :string
  end
end
