class Relationship < ActiveRecord::Base

  belongs_to :from,     :foreign_key => "from_sobject_id", :class_name => "Sobject"
  belongs_to :to,       :foreign_key => "to_sobject_id",   :class_name => "Sobject"
  belongs_to :relation

  acts_as_list :scope => :from_sobject_id

  validates_presence_of   :from, :to, :relation
  validates_associated    :from, :to, :relation
  validates_uniqueness_of :relation_id, :scope => [ :relation_id, :from_sobject_id, :to_sobject_id ]

  def <=>(other_relation)
    self.to.content.title <=> other_relation.to.content.title
  end

  def category
    # FIXME: we used to have a database relation with category, now we have one with the table "relation"
    relation
  end

  # Liquid support

  def to_liquid
    RelationshipDrop.new(self)
  end

end
