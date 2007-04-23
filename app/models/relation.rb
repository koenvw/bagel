class Relation < ActiveRecord::Base
  belongs_to :content_type
  validates_presence_of :name
  validates_presence_of :content_type_id
  validates_uniqueness_of :name
end
