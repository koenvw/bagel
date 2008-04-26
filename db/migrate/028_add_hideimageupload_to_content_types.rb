class AddHideimageuploadToContentTypes < ActiveRecord::Migration
  def self.up
    add_column :content_types, :hide_imageuploads, :tinyint
  end

  def self.down
  end
end
