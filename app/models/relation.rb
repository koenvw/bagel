class Relation < ActiveRecord::Base

  belongs_to              :content_type
  has_and_belongs_to_many :content_types
  belongs_to              :imported_relation, :class_name => 'Relation', :foreign_key => 'imported_relation_id'

  validates_presence_of   :name
  validates_presence_of   :content_type_id, :if => lambda { |r| !r.is_external }
  validates_uniqueness_of :name

  # Liquid support

  def to_liquid
    RelationDrop.new(self)
  end

  def is_translation_relation?
    name =~ /^Translation - /
  end

end
