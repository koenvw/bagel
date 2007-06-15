class Tag < ActiveRecord::Base
  acts_as_enhanced_nested_set
  has_and_belongs_to_many :sobjects, :join_table => "categories_sobjects", :foreign_key => "category_id"
                          #FIXME: rename category_sobjects to tags_sobjects
  validates_presence_of :name
  serialize :content_type_ids

  def <=>(other_tag)
    self.name.downcase <=> other_tag.name.downcase
  end

  def content_types
    return [] if content_type_ids.nil?
    type_ids = [content_type_ids].join(",")
    ContentType.find(:all,:conditions => ["id IN (#{type_ids})"])
  end


end
