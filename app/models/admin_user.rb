class AdminUser < ActiveRecord::Base
  has_and_belongs_to_many :admin_roles
  
  attr_protected :is_active
  attr_protected :password
  attr_protected :password_hash
  attr_protected :password_salt
  
  validates_uniqueness_of   :username
  validates_presence_of     :username, :firstname, :lastname, :password_hash, :email_address
  
  before_destroy :keep_admin_user
  
  cattr_accessor :current_user # for userstamp plugin
  
  self.user_model_name = :admin_users
  
  # Prevent the admin user from being deleted
  def keep_admin_user
    raise 'Cannot delete admin user' if self.username == 'admin'
  end
  
  # Returns the full name of this user
  def fullname
    "#{self.firstname} #{self.lastname}"
  end
  
  # Assigns a new password and stores salt+hash in the database
  def password=(password)
    self.password_salt = [Array.new(8) { rand(256).chr }.join].pack('m').chomp
    self.password_hash = Digest::SHA256.hexdigest(password + self.password_salt)
  end
  
  # Returns the user with matching username and password if authentication
  # succeeds, nil otherwise
  def self.authenticate(username, password)
    # Find user
    user = self.find(:first, :conditions => [ 'username = ? AND is_active = ?', username, true ])
    return nil if user.blank?
    
    # Check password
    password_hash = Digest::SHA256.hexdigest(password + user.password_salt)
    return nil if password_hash != user.password_hash
    
    user
  end
  
  # Returns this user's permissions
  def admin_permissions
    admin_roles.collect { |role| role.admin_permissions }.flatten.uniq.map {|permission| permission.name.to_sym }
  end
  
  # Checks whether the user has the given permission
  def has_admin_permission?(a_admin_permission)
    username == 'admin' || admin_permissions.include?(a_admin_permission)
  end
  
end
