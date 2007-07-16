class RenameMediasToMediaItems < ActiveRecord::Migration
  def self.up
    rename_table :medias, :media_items
  end

  def self.down
    rename_table :media_items, :medias
  end
end
