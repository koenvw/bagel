# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 1) do

  create_table "admin_permissions", :force => true do |t|
    t.column "name", :string
  end

  create_table "admin_permissions_admin_roles", :id => false, :force => true do |t|
    t.column "admin_permission_id", :integer, :null => false
    t.column "admin_role_id",       :integer, :null => false
  end

  create_table "admin_roles", :force => true do |t|
    t.column "name", :string
  end

  create_table "admin_roles_admin_users", :id => false, :force => true do |t|
    t.column "admin_role_id", :integer, :null => false
    t.column "admin_user_id", :integer
  end

  create_table "admin_users", :force => true do |t|
    t.column "username",                  :string,   :limit => 80
    t.column "password_hash",             :string,   :limit => 64
    t.column "email_address",             :string,   :limit => 60
    t.column "firstname",                 :string,   :limit => 40
    t.column "lastname",                  :string,   :limit => 40
    t.column "password_salt",             :string,   :limit => 40
    t.column "created_at",                :datetime
    t.column "updated_at",                :datetime
    t.column "is_active",                 :boolean,                :default => true
    t.column "language_code",             :string,   :limit => 5,  :default => "",   :null => false
    t.column "password_code",             :string
    t.column "email_address_unconfirmed", :string
    t.column "email_address_code",        :string
    t.column "reset_code",                :string
  end

  create_table "books", :force => true do |t|
    t.column "title",      :string
    t.column "created_on", :datetime
    t.column "updated_on", :datetime
    t.column "intro",      :text
  end

  create_table "categories", :force => true do |t|
    t.column "name",             :string
    t.column "protected",        :boolean
    t.column "parent_id",        :integer
    t.column "created_on",       :datetime
    t.column "updated_on",       :datetime
    t.column "extra_info",       :string,   :default => ""
    t.column "categories_count", :integer
    t.column "lft",              :integer
    t.column "rgt",              :integer
    t.column "type",             :string,   :default => "", :null => false
  end

  add_index "categories", ["name"], :name => "index_categories_on_name"
  add_index "categories", ["parent_id"], :name => "index_categories_on_parent_id"

  create_table "categories_sobjects", :id => false, :force => true do |t|
    t.column "sobject_id",  :integer, :default => 0, :null => false
    t.column "category_id", :integer, :default => 0, :null => false
  end

  create_table "containers", :force => true do |t|
    t.column "title",       :string
    t.column "description", :text
    t.column "created_on",  :datetime
    t.column "updated_on",  :datetime
  end

  create_table "content_types", :force => true do |t|
    t.column "name",              :string
    t.column "core_content_type", :string,   :default => "", :null => false
    t.column "description",       :text,     :default => "", :null => false
    t.column "extra_info",        :string,   :default => "", :null => false
    t.column "created_on",        :datetime
    t.column "updated_on",        :datetime
  end

  create_table "db_files", :force => true do |t|
    t.column "data", :binary
  end

  create_table "form_definitions", :force => true do |t|
    t.column "name",        :string
    t.column "template",    :text
    t.column "redirect_to", :string
    t.column "created_on",  :datetime
    t.column "updated_on",  :datetime
    t.column "action",      :string
  end

  create_table "forms", :force => true do |t|
    t.column "name",               :string
    t.column "data",               :text
    t.column "form",               :text
    t.column "form_definition_id", :integer
    t.column "created_on",         :datetime
    t.column "updated_on",         :datetime
  end

  add_index "forms", ["name"], :name => "index_forms_on_name"
  add_index "forms", ["form_definition_id"], :name => "index_forms_on_form_definition_id"

  create_table "galleries", :force => true do |t|
    t.column "title",      :string
    t.column "created_on", :datetime
    t.column "updated_on", :datetime
  end

  create_table "generator_files", :force => true do |t|
    t.column "name",         :string
    t.column "generator_id", :integer
    t.column "file_path",    :string
  end

  create_table "generators", :force => true do |t|
    t.column "name",         :string
    t.column "template",     :text
    t.column "website_id",   :integer
    t.column "content_type", :string
    t.column "preview_url",  :string
    t.column "created_on",   :datetime
    t.column "updated_on",   :datetime
    t.column "description",  :text
  end

  add_index "generators", ["name"], :name => "index_generators_on_name"
  add_index "generators", ["website_id"], :name => "index_generators_on_website_id"
  add_index "generators", ["content_type"], :name => "index_generators_on_content_type"

 
  create_table "images", :force => true do |t|
    t.column "image",       :string
    t.column "created_on",  :datetime
    t.column "updated_on",  :datetime
    t.column "title",       :string,   :default => ""
    t.column "description", :text
  end

  create_table "links", :force => true do |t|
    t.column "title",       :string
    t.column "url",         :string
    t.column "description", :text
    t.column "status",      :string
    t.column "created_on",  :datetime
    t.column "updated_on",  :datetime
  end

  create_table "mail_deliveries", :force => true do |t|
    t.column "message_id",   :string
    t.column "recipient",    :string
    t.column "site_user_id", :string
    t.column "content",      :text
    t.column "status",       :string
    t.column "created_on",   :datetime
    t.column "updated_on",   :datetime
  end

  add_index "mail_deliveries", ["message_id"], :name => "index_mail_deliveries_on_message_id"
  add_index "mail_deliveries", ["recipient"], :name => "index_mail_deliveries_on_recipient"
  add_index "mail_deliveries", ["site_user_id"], :name => "index_mail_deliveries_on_site_user_id"

  create_table "media_thumbnails", :force => true do |t|
    t.column "content_type", :string
    t.column "filename",     :string
    t.column "size",         :integer
    t.column "thumbnail",    :string
    t.column "parent_id",    :integer
    t.column "created_on",   :datetime
    t.column "updated_on",   :datetime
  end

  create_table "medias", :force => true do |t|
    t.column "title",        :string
    t.column "description",  :string
    t.column "content",      :text
    t.column "type",         :string
    t.column "content_type", :string
    t.column "filename",     :string
    t.column "size",         :integer
    t.column "width",        :integer
    t.column "height",       :integer
    t.column "db_file_id",   :integer
    t.column "thumbnail",    :string
    t.column "parent_id",    :integer
    t.column "created_on",   :datetime
    t.column "updated_on",   :datetime
  end

  create_table "menus", :force => true do |t|
    t.column "name",        :string
    t.column "parent_id",   :integer
    t.column "created_on",  :datetime
    t.column "updated_on",  :datetime
    t.column "menus_count", :integer
    t.column "lft",         :integer
    t.column "rgt",         :integer
  end

  add_index "menus", ["name"], :name => "index_menus_on_name"
  add_index "menus", ["parent_id"], :name => "index_menus_on_parent_id"

  create_table "news", :force => true do |t|
    t.column "title",      :string
    t.column "intro",      :text
    t.column "body",       :text
    t.column "created_on", :datetime
    t.column "updated_on", :datetime
  end

  create_table "pages", :force => true do |t|
    t.column "title",      :string
    t.column "body",       :text
    t.column "author_id",  :integer
    t.column "created_on", :datetime
    t.column "updated_on", :datetime
  end

  create_table "queued_mails", :force => true do |t|
    t.column "object", :text
    t.column "mailer", :string
  end

  create_table "relations", :force => true do |t|
    t.column "name",            :string
    t.column "content_type_id", :integer
    t.column "created_on",      :datetime
    t.column "updated_on",      :datetime
    t.column "name_reverse",    :string
  end

  create_table "relationships", :force => true do |t|
    t.column "from_sobject_id", :integer
    t.column "to_sobject_id",   :integer
    t.column "category_id",     :integer
    t.column "position",        :integer, :default => 0
    t.column "extra_info",      :string,  :default => ""
  end

  add_index "relationships", ["from_sobject_id", "to_sobject_id", "category_id"], :name => "from_sobject_id_to_sobject_id_category_id", :unique => true
  add_index "relationships", ["position"], :name => "index_relationships_on_position"

  create_table "settings", :force => true do |t|
    t.column "name",           :string
    t.column "value",          :text
    t.column "value_type",     :string
    t.column "parent_id",      :integer
    t.column "created_on",     :datetime
    t.column "updated_on",     :datetime
    t.column "settings_count", :integer
    t.column "lft",            :integer
    t.column "rgt",            :integer
  end

  add_index "settings", ["name"], :name => "index_settings_on_name"
  add_index "settings", ["parent_id"], :name => "index_settings_on_parent_id"

  create_table "site_users", :force => true do |t|
    t.column "name",         :string
    t.column "login",        :string
    t.column "email",        :string
    t.column "password",     :string
    t.column "active",       :boolean
    t.column "created_on",   :datetime
    t.column "updated_on",   :datetime
    t.column "logged_in_on", :datetime
  end

  create_table "sitems", :force => true do |t|
    t.column "name",         :string
    t.column "content_id",   :integer
    t.column "content_type", :string
    t.column "parent_id",    :integer
    t.column "status",       :string
    t.column "website_id",   :integer
    t.column "link",         :string
    t.column "publish_from", :datetime
    t.column "publish_till", :datetime
    t.column "publish_date", :datetime
    t.column "created_on",   :datetime
    t.column "updated_on",   :datetime
    t.column "click_count",  :integer,  :default => 0
    t.column "sobject_id",   :integer
  end

  add_index "sitems", ["content_id", "content_type", "website_id"], :name => "content_id_content_type_website_id", :unique => true
  add_index "sitems", ["name"], :name => "index_sitems_on_name"
  add_index "sitems", ["parent_id"], :name => "index_sitems_on_parent_id"
  add_index "sitems", ["status"], :name => "index_sitems_on_status"
  add_index "sitems", ["publish_from"], :name => "index_sitems_on_publish_from"
  add_index "sitems", ["publish_till"], :name => "index_sitems_on_publish_till"
  add_index "sitems", ["sobject_id"], :name => "index_sitems_on_sobject_id"

  create_table "sobjects", :force => true do |t|
    t.column "content_id",          :integer
    t.column "content_type",        :string
    t.column "cached_category_ids", :string,   :default => ""
    t.column "created_by",          :integer
    t.column "updated_by",          :integer
    t.column "cached_categories",   :string
    t.column "created_on",          :datetime
    t.column "updated_on",          :datetime
    t.column "content_type_id",     :integer
  end

  add_index "sobjects", ["content_id", "content_type"], :name => "content_id_content_type", :unique => true
  add_index "sobjects", ["cached_category_ids"], :name => "index_sobjects_on_cached_category_ids"

  create_table "tags", :force => true do |t|
    t.column "name",       :string
    t.column "extra_info", :string
    t.column "parent_id",  :integer
    t.column "active",     :boolean,  :null => false
    t.column "lft",        :integer
    t.column "rgt",        :integer
    t.column "created_on", :datetime
    t.column "updated_on", :datetime
  end

  create_table "url_mappings", :force => true do |t|
    t.column "path",            :string
    t.column "options",         :text
    t.column "position",        :integer
    t.column "website_id",      :text
    t.column "content_type_id", :integer
    t.column "created_on",      :datetime
    t.column "updated_on",      :datetime
  end

  create_table "websites", :force => true do |t|
    t.column "name",       :string
    t.column "domain",     :string
    t.column "created_on", :datetime
    t.column "updated_on", :datetime
  end

end