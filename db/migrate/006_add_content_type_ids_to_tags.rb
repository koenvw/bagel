class AddContentTypeIdsToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :content_type_ids, :text
  end

  def self.down
    remove_column :tags, :content_type_ids
  end
end
