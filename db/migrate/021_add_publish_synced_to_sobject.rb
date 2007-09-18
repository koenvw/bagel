class AddPublishSyncedToSobject < ActiveRecord::Migration
  def self.up
    add_column :sobjects, :publish_synced, :boolean
  end

  def self.down
    remove_column :sobjects, :publish_synced
  end
end 
