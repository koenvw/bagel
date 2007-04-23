class Category < ActiveRecord::Base
  acts_as_enhanced_nested_set
  has_and_belongs_to_many :sobjects
  validates_presence_of :name

  def before_destroy
    raise 'protected' if protected?
  end

  def <=>(other_category)
    self.name <=> other_category.name
  end

  ### DEPRECATED ###
  def self.create_sorted(*attributes)
    $stderr.puts('DEPRECATION WARNING: Category.create_sorted is deprecated; please use Category.create and sort afterwards instead')
    self.create(attributes)
  end

  def self.find_all_by_parent_name(name)
    $stderr.puts('DEPRECATION WARNING: Category.find_all_by_parent_name is deprecated; please use Category.find_by_parent_name.children instead')
    raise NotImplementedError.new("Category.find_all_by_parent_name is deprecated; please use Category.find_by_parent_name.children instead")
  end

end
