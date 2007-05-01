class AdminRole < ActiveRecord::Base #:nodoc:
  has_and_belongs_to_many :admin_users
  has_and_belongs_to_many :admin_permissions
end
