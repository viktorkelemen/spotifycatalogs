class Album < ActiveRecord::Base
  default_scope order('date DESC')
end
