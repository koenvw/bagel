class AddImportedRelationIdToRelations < ActiveRecord::Migration
  def self.up
    add_column :relations, :imported_relation_id, :integer
  end

  def self.down
    remove_column :relations, :imported_relation_id
  end
end
