class CreateWorkflow < ActiveRecord::Migration
  def self.up
    # Create workflow table
    create_table :workflows do |t|
      t.column :name,       :string
      t.column :description,:text
      t.column :updated_at, :datetime
      t.column :created_at, :datetime
    end

    # Create workflow_steps table
    create_table :workflow_steps do |t|
      t.column :name,       :string
      t.column :description,:text
      t.column :admin_role_id,   :integer
      t.column :is_final,   :boolean
      t.column :position,   :integer
      t.column :workflow_id,:integer
      t.column :updated_at, :datetime
      t.column :created_at, :datetime
    end
    # Create workflow_actions table
    create_table :sobjects_workflow_steps do |t|
      t.column :sobject_id,        :integer, :null => false
      t.column :workflow_step_id,  :integer, :null => false
      t.column :checked,           :boolean
      t.column :admin_user_id,     :integer, :null => false
      t.column :updated_at,        :datetime
      t.column :created_at,        :datetime
    end

    add_column :content_types, :workflow_id, :integer
  end

  def self.down
    drop_table :workflows
    drop_table :workflow_steps
    remove_column :content_types, :workflow_id
  end
end
