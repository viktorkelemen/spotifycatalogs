class CatalogsController < ApplicationController

  def index
    @catalogs = Catalog.all
  end

  def show
    @catalog = Catalog.find_by_name(params[:name])
  end

end
