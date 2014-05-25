class Album < ActiveRecord::Base
  default_scope { order('date DESC') }

  belongs_to :catalog

end
