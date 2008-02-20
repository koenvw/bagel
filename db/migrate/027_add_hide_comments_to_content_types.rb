class AddHideCommentsToContentTypes < ActiveRecord::Migration
  
  def self.up
    add_column :content_types, :hide_comment, :boolean
  end
  
  def self.down
    remove_column :content_types, :hide_comment
  end
  
  
end