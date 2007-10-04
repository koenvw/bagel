require 'YAML'
def admin_menu
  admin_menu_project_filename = File.join(RAILS_ROOT, 'config', 'admin_menu.yml')
  admin_menu_bagel_filename   = File.join(File.dirname(__FILE__), 'admin_menu.yml')
  
  if File.exist?(admin_menu_project_filename)
    # Read admin menu in project
    File.open(admin_menu_project_filename) { |io| YAML::load(io) } || {}
  else
    # Read admin menu in bagel plugin
    File.open(admin_menu_bagel_filename) { |io| YAML::load(io) } || {}
  end
end
