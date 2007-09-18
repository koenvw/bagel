class AddIsTranslatableToWorkflowSteps < ActiveRecord::Migration
  def self.up
    add_column    :workflow_steps, :is_translatable, :boolean
    rename_column :workflow_steps, :optional,        :is_optional
  end

  def self.down
    remove_column :workflow_steps, :is_translatable
    rename_column :workflow_steps, :is_optional,     :optional
  end
end 
