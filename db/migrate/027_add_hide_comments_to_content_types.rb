class AddHideCommentsToContentTypes < ActiveRecord::Migration

  def self.up
    add_column :content_types, :hide_comments, :boolean, :default => true
  end

  def self.down
    remove_column :content_types, :hide_comments
  end

end
