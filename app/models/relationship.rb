class Relationship < ActiveRecord::Base
  belongs_to :from, :foreign_key => "from_sobject_id", :class_name => "Sobject"
  belongs_to :to,   :foreign_key => "to_sobject_id",   :class_name => "Sobject"
  belongs_to :relation, :foreign_key => "category_id"
  acts_as_list :scope => :from_sobject_id

  validates_presence_of :from, :to, :category # make sure we have associated objects
  validates_associated :from, :to, :category # make sure that our associated objects are valid
  validates_uniqueness_of :category_id, :scope => [:category_id, :from_sobject_id, :to_sobject_id] #make sure that we don't have duplicates

  def <=>(other_relation)
    self.to.content.title <=> other_relation.to.content.title
  end

  def category
    # FIXME: we used to have a database relation with category, now we have one with the table "relation"
    relation
  end

  def self.add(options)
    raise NotImplementedError.new("Relationship.add is not implemented")
    #FIXME:
    return nil unless !options[:from].nil? && !options[:to].nil? && !options[:name].nil?
    return nil unless Sobject.exists?(options[:from]) && Sobject.exists?(options[:to])
  end
end

