class ContentType < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :core_content_type
  validates_uniqueness_of :name
  belongs_to :workflow
end
