class UrlMapping < ActiveRecord::Base
  acts_as_list
  belongs_to :website

  validates_presence_of :path
  validates_presence_of :options
  validates_each :options do |model,attr,value|
    model.errors.add(attr, "can not be parsed to a Hash") unless !value.nil? && YAML.load(value).class == Hash
  end
  validates_uniqueness_of :path


end
