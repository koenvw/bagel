class AddOptionalToWorkflowSteps < ActiveRecord::Migration
  def self.up
    add_column :workflow_steps, :optional, :boolean
  end

  def self.down
    remove_column :workflow_steps, :optional
  end
end
