class AddLanguageToSobject < ActiveRecord::Migration
  def self.up
    add_column :sobjects, :language, :string
  end

  def self.down
    remove_column :sobjects, :language
  end
end 
