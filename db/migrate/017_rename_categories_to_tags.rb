class RenameCategoriesToTags < ActiveRecord::Migration
  def self.up
    rename_table  :categories_sobjects, :sobjects_tags
    rename_column :relationships, :category_id, :relation_id
    rename_column :sobjects_tags, :category_id, :tag_id
    rename_column :sobjects,      :cached_categories,   :cached_tags
    rename_column :sobjects,      :cached_category_ids, :cached_tag_ids
  end

  def self.down
    rename_table  :sobjects_tags, :categories_sobjects
    rename_column :sobjects_tags, :tag_id, :category_id
    rename_column :relationships, :relation_id, :category_id
    rename_column :sobjects,      :cached_tags,    :cached_categories
    rename_column :sobjects,      :cached_tag_ids, :cached_category_ids
  end
end
