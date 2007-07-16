class AddAttachmentFuStuffToImage < ActiveRecord::Migration
  def self.up
    add_column :images, :size,          :integer
    add_column :images, :content_type,  :string
    add_column :images, :filename,      :string
    add_column :images, :height,        :integer
    add_column :images, :width,         :integer
    add_column :images, :parent_id,     :integer
    add_column :images, :thumbnail,     :string

    # Depends on backend...
    add_column :images, :db_file_id,    :integer
    add_column :images, :data,          :binary
  end

  def self.down
    remove_column :images, :size
    remove_column :images, :content_type
    remove_column :images, :filename
    remove_column :images, :height
    remove_column :images, :width
    remove_column :images, :parent_id
    remove_column :images, :thumbnail

    # Depends on backend...
    remove_column :images, :db_file_id
    remove_column :images, :data
  end
end
