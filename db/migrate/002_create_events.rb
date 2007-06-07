class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.column :title,       :string
      t.column :event_start, :datetime
      t.column :event_stop,  :datetime
      t.column :intro,       :text
      t.column :body,       :text
      t.column :updated_at, :datetime
      t.column :created_at, :datetime
    end

  end

  def self.down
    drop_table :events
  end
end
