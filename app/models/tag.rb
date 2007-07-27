class Tag < ActiveRecord::Base

  acts_as_enhanced_nested_set

  has_and_belongs_to_many :sobjects, :join_table => "sobjects_tags"

  validates_presence_of   :name
  validates_uniqueness_of :name # name must be unique, so we don't run in to troubles when looking up tags by name (Sobject.find_with_parameters)

  serialize :content_type_ids

  def <=>(other_tag)
    self.name.downcase <=> other_tag.name.downcase
  end

  def content_types
    return [] if content_type_ids.nil?
    # convert to array (.to_a is deprecated in this situation ?)
    type_ids = [content_type_ids].flatten
    ContentType.find(:all,:conditions => ["id IN (#{type_ids.join(",")})"])
  end

  # Liquid support

  def to_liquid
    TagDrop.new(self)
  end

end
