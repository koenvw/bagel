class AddIsExternalToRelations < ActiveRecord::Migration
  def self.up
    add_column :relations, :is_external,   :boolean
    add_column :relations, :external_type, :string
  end

  def self.down
    remove_column :relations, :is_external
    remove_column :relations, :external_type
  end
end
