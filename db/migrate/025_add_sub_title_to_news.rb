class AddSubTitleToNews < ActiveRecord::Migration
  def self.up
    add_column :news, :sub_title, :string
  end

  def self.down
    remove_column :news, :sub_title
  end
end
