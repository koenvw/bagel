class Relation < ActiveRecord::Base

  belongs_to              :content_type
  has_and_belongs_to_many :content_types

  validates_presence_of   :name
  validates_presence_of   :content_type_id
  validates_uniqueness_of :name

  # Liquid support

  def to_liquid
    RelationDrop.new(self)
  end

end
