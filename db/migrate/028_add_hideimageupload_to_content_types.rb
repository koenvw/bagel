class AddHideimageuploadToContentTypes < ActiveRecord::Migration
  def self.up
    add_column :content_types, :hide_imageuploads, :boolean, :default => true
  end

  def self.down
    remove_column :content_types, :hide_imageuploads
  end
end
