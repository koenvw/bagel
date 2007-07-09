def admin_menu
  # Read admin menu in Bagel plugin
  admin_menu_bagel_filename = File.join(File.dirname(__FILE__), 'admin_menu.yml')
  admin_menu_bagel = File.exist?(admin_menu_bagel_filename) ? (File.open(admin_menu_bagel_filename) { |io| YAML::load(io) } || {}) : {}

  # Read admin menu in project
  admin_menu_project_filename = File.join(RAILS_ROOT, 'admin_menu.yml')
  admin_menu_project = File.exist?(admin_menu_project_filename) ? (File.open(admin_menu_project_filename) { |io| YAML::load(io) } || {}) : {}

  # TODO Merge both files
  admin_menu_merged = admin_menu_bagel
  admin_menu_merged
end
