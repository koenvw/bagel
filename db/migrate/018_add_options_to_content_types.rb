class AddOptionsToContentTypes < ActiveRecord::Migration
  def self.up
    add_column :content_types, :hidden, :boolean, :default => false
    add_column :content_types, :hide_websites, :boolean, :default => false
    add_column :content_types, :hide_tags, :boolean, :default => false
    add_column :content_types, :hide_relations, :boolean, :default => false
  end

  def self.down
    remove_column :content_types, :hidden
    remove_column :content_types, :hide_websites
    remove_column :content_types, :hide_tags
    remove_column :content_types, :hide_relations
  end
end 
