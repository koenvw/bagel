class CreateBusinessRules < ActiveRecord::Migration
  def self.up
    create_table :business_rules do |t|
      t.column :name,             :string
      t.column :content_type_id,  :integer
      t.column :code,             :text
    end
  end

  def self.down
    drop_table :business_rules
  end
end
