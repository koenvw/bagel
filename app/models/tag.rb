class Tag < ActiveRecord::Base
  # we use virtual roots with the type column as scope
  acts_as_enhanced_nested_set
  has_and_belongs_to_many :sobjects, :join_table => "categories_sobjects", :foreign_key => "category_id"
                          #FIXME: rename category_sobjects to tags_sobjects
  validates_presence_of :name

  def <=>(other_tag)
    self.name <=> other_tag.name
  end
end
