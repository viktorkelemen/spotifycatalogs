class AddDescrtiptionToCatalogs < ActiveRecord::Migration
  def change
    add_column :catalogs, :description, :string
  end
end
