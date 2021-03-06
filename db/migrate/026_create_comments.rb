class CreateComments < ActiveRecord::Migration

  def self.up
    # Create comments table
    create_table :comments do |t|
      t.column :body,          :text
      t.column :admin_user_id, :integer
      t.column :updated_on,    :datetime
      t.column :created_on,    :datetime
    end

    #Create sobjects_comments table
    create_table :sobjects_comments, :id => false do |t|
      t.column :sobject_id,    :integer
      t.column :comment_id,    :integer
    end

  end

  def self.down
      drop_table :comments
      drop_table :sobjects_comments
  end
end
