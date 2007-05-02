class GeneratorFolder < ActiveRecord::Base
  has_many :generators
  belongs_to :website
  acts_as_enhanced_nested_set :scope => :website_id
  validates_presence_of :name
  validates_presence_of :website

end
