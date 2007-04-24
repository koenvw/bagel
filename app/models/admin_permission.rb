class AdminPermission < ActiveRecord::Base
  has_and_belongs_to_many :admin_roles
  validates_presence_of :name
  
  def self.sync_permissions
    # Load all controller classes and dependencies
    self.load_all_controllers
     
    # Collect permissions
    permission_schemes = self.subclasses_of(ApplicationController).collect { |controller| controller.permission_scheme }
    
    new_permissions = permission_schemes.compact.collect { |p| p.values }.flatten.uniq
    old_permissions = AdminPermission.find(:all).collect { |p| p.name.to_sym }
    
    permissions_to_be_removed = old_permissions - new_permissions
    permissions_to_be_added   = new_permissions - old_permissions
    
    transaction do
      # Delete some permissions
      permissions_to_be_removed.each do |permission|
        puts 'Removing permission ' + permission.to_s
        AdminPermission.find_by_name(permission.to_s).destroy
      end
      
      # Add some permissions
      permissions_to_be_added.each do |permission|
        puts 'Adding permission ' + permission.to_s
        AdminPermission.create(:name => permission.to_s)
      end
    end
  end
  
  private
  
  # TODO: not AdminPermission-specific, so move this elsewhere
  def self.load_all_controllers
    # Load application controller
    application_controller = File.join(RAILS_ROOT, 'app', 'controllers', 'application.rb')
    require application_controller
    
    # Load other controllers
    other_controllers_glob = File.join(RAILS_ROOT, 'app', 'controllers', '**', '*_controller.rb')
    Dir.glob(other_controllers_glob).each do |controller|
      require controller
    end
    
    
    # should we check to see if this is defined? I.E. will this code ever run
    # outside of the framework environment...?
    controller_files = Dir[RAILS_ROOT + "/vendor/plugins/bagel/app/controllers/**/*_controller.rb"]
    
    # we need to load all the controllers...
    controller_files.each do |file_name|
      require file_name #if /_controller.rb$/ =~ file_name
    end
     
  end
  
  # TODO: not AdminPermission-specific, so move this elsewhere
  def self.descendant_classes_of(a_superclass)
    descendants = []
    
    # Get all (loaded) classes
    ObjectSpace.each_object(Class) do |klass|
      # Skip non-subclasses
      next if a_superclass == klass
      next unless klass.ancestors.include?(a_superclass)
      
      # Add to list of subclasses
      descendants << klass
    end
    
    # Filter double classes
    descendants.uniq
  end

end
