class CreateGeneratorFolders < ActiveRecord::Migration
  def self.up
    create_table :generator_folders do |t|
      t.column :name,       :string
      t.column :website_id, :integer
      t.column :parent_id,  :integer
      t.column :lft,        :integer
      t.column :rgt,       :integer
      t.column :updated_at, :datetime
      t.column :created_at, :datetime
    end

    add_column :generators, :generator_folder_id, :integer

  end

  def self.down
    drop_table :generator_folders
    remove_column :generators, :generator_folder_id
  end
end
