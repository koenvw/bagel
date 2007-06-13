class WorkflowStep < ActiveRecord::Base
  acts_as_list
  validates_presence_of :name, :admin_role_id
  validates_uniqueness_of :name
  belongs_to :admin_role
  belongs_to :workflow
  has_many :workflow_actions
  has_many :sobjects, :through => :workflow_actions

  def <=>(other_step)
    self.position <=> other_step.position
  end
end
