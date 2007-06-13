class Workflow < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :content_types
  has_many :workflow_steps
end
