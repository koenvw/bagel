class PrepareMediaItemThumbnails < ActiveRecord::Migration
  def self.up
    # Fix table name
    rename_table :media_thumbnails, :media_item_thumbnails

    # Add missing columns
    add_column :media_item_thumbnails, :height,     :integer
    add_column :media_item_thumbnails, :width,      :integer
    add_column :media_item_thumbnails, :db_file_id, :integer
  end

  def self.down
    rename_table :media_item_thumbnails, :media_thumbnails

    remove_column :media_item_thumbnails, :height
    remove_column :media_item_thumbnails, :width
    remove_column :media_item_thumbnails, :db_file_id
  end
end
