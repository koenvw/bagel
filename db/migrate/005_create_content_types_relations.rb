class CreateContentTypesRelations < ActiveRecord::Migration
  def self.up
    create_table :content_types_relations, :id => false do |t|
      t.column :content_type_id,  :integer, :null => false
      t.column :relation_id,      :integer, :null => false
    end
  end

  def self.down
    drop_table :content_types_relations
  end
end
