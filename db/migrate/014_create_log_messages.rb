class CreateLogMessages < ActiveRecord::Migration
  def self.up
    create_table :log_messages do |t|
      t.column :severity,       :integer  # HIGH... MEDIUM... LOW
      t.column :kind,           :string   # exception... admin action... user login failed...
      t.column :created_at,     :datetime
      t.column :message,        :string   # will use Exception#to_s when passed an exception
      t.column :extra_info,     :text     # YAML with extra info
      t.column :request_url,    :string
      t.column :referrer_url,   :string
      t.column :admin_user_id,  :string   # user that was logged in when the log message was created
    end
  end

  def self.down
    drop_table :log_messages
  end
end
