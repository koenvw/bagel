#
# Insert line: ["require 'plugins/app_config/lib/configuration'","require 'memcache_util'","require 'mime/types'"]
# before Initializer.run in conf/environment.rb file
#
#install.rb
#- evironment.rb
#- config/environments
#- application.rb
#- routes
#- remove index.html
#- copy schema.rb ?

file = File.join(File.dirname(__FILE__), '../../../config/environment.rb')
unless File.exists?(file)
  STDERR.puts("ERROR: Could not locate config/environment.rb file.")
  exit(1)
end

def insert_line(line,before,file)
  # Tip from http://pleac.sourceforge.net/pleac_ruby/fileaccess.html
  # 'Modifying a File in Place Without a Temporary File'
  output= ""
  inserted = false
  File.open(file, 'r+') do |f|   # open file for update
    # read into array of lines and iterate through lines
    f.readlines.each do |line|
      puts line
      unless inserted
        if line.gsub(/#.*/, '').include?(line)
          inserted = true
        elsif line.gsub(/#.*/, '').include?('Rails::Initializer.run')
          output << line
          output << "\n"
          inserted = true
        end
      end
      output << line
    end
    f.pos = 0                     # back to start
    f.print output                # write out modified lines
    f.truncate(f.pos)             # truncate to new length
  end

  unless inserted
      STDERR.puts <<END
ERROR: Could not update config/environment.rb
To finish installation try to add the following line to
config/environment.rb manually:
\t#{LINE_TO_INSERT}
NOTE: line must be inserted before Rails::Initializer.run()
END
      exit(1)
  end
end

# add requires
["require 'plugins/bagel/lib/configuration'","require 'vendor/plugins/bagel/admin_menu' ","require 'memcache_util'","require 'mime/types'","require 'htmlentities'","require 'net/ftp'","require 'RMagick'","require 'liquid'"].each do |line|
  insert_line(line, 'Rails::Initializer.run', file)
end


# add config
config = <<EOC
  # Load engines plugin first,
  config.plugins = ["engines","betternestedset","bagel","*"]

  #Application Config
  config.app_config.content_types = %w( News MediaItem Form FormDefinition Container SiteUser Document Generator )
  config.app_config.content_status = %w( Draft Reviewed Published Hidden )
  config.app_config.form_actions = %w( store_as_site_user remove_as_site_user ) 

  # akismet key
  config.app_config.akismet_key = ""
  config.app_config.akismet_url = ""
  
  # assistant ("content_type" => "controller_name")
  config.app_config.assistant_controllers = { }

  # Domains
  config.app_config.domain_map = {} # domainify_name => name in bagel(websites)
  config.app_config.websites = {} # website_name(bagel) => website_id

  # wizards
  config.app_config.wizard_for = [] # array of content type names

  # multisite_setup
  config.app_config.multisite_setup = true

  # admin menu
  config.app_config.admin_menu = admin_menu 

  # email validation
  config.app_config.email_expression = /^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/i

  # set path for page_caching
  config.action_controller.page_cache_directory = RAILS_ROOT + "/public/cache/"
  config.app_config.cache_to_filesytem = true

EOC
insert_line(config, 'See Rails::Configuration for more options', file)

# add bagel_application_setup
file = File.join(File.dirname(__FILE__), '../../../app/controllers/application.rb')
unless File.exists?(file)
  STDERR.puts("ERROR: Could not locate config/environment.rb file.")
  exit(1)
end

insert_line("bagel_application_setup", 'end', file)

