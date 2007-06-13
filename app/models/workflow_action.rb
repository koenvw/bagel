class WorkflowAction < ActiveRecord::Base
  validates_presence_of :sobject_id, :admin_user_id, :workflow_step_id
  validates_uniqueness_of :sobject_id, :scope => [:sobject_id, :admin_user_id, :workflow_step_id] #make sure that we don't have duplicates
  belongs_to :sobject
  belongs_to :admin_user
  belongs_to :workflow_step
end
