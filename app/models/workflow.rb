class Workflow < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :content_types
  has_many :workflow_steps

  def after_destroy
    ContentType.update_all "workflow_id = null", "workflow_id = #{self.id}"
  end

  # FIXME: what if we delete a workflow that has steps and actions ?

end
