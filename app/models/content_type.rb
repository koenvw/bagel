class ContentType < ActiveRecord::Base

  validates_presence_of   :name
  validates_presence_of   :core_content_type
  validates_uniqueness_of :name

  belongs_to              :workflow
  has_many                :business_rules
  has_and_belongs_to_many :relations
  has_many                :sobjects

  # Liquid support

  def to_liquid
    ContentTypeDrop.new(self)
  end

end
