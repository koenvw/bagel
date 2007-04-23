class AdminRole < ActiveRecord::Base
  has_and_belongs_to_many :admin_users
  has_and_belongs_to_many :admin_permissions
end
