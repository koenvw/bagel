class AddContentTypeIdToGenerators < ActiveRecord::Migration
  def self.up
    add_column :generators, :content_type_id, :integer
    rename_column :generators, :content_type, :core_content_type
  end

  def self.down
    remove_column :generators, :content_type_id
    rename_column :generators, :core_content_type, :content_type
  end
end
