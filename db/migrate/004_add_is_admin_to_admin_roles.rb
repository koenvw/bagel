class AddIsAdminToAdminRoles < ActiveRecord::Migration
  def self.up
    add_column :admin_roles, :is_admin, :boolean

  end
end
