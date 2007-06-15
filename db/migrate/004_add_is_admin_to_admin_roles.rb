class AddIsAdminToAdminRoles < ActiveRecord::Migration
  def self.up
    add_column :admin_roles, :is_admin, :boolean
  end

  def self.down
    remove_column :admin_roles, :is_admin
  end
end
