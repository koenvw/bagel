namespace :bagel do

  desc 'Update all pictures according to ImageSettings'
  task :update_pictures => :environment do
    Picture.find(:all, :conditions => 'parent_id IS NULL').each do |picture|
      picture.update_thumbnails
    end
  end

  namespace :db do

    desc 'Puts all permissions used in all controllers into the database and removes unused permission from the database'
    task :sync_permissions => :environment do
      AdminPermission.sync_permissions
    end

    desc 'Dump all data in the current database to yaml files under db/demo_data'
    task :dump => :environment do
      sql = "SELECT * FROM %s"
      skip_tables = ["schema_info","plugin_schema_info", "globalize_countries", "globalize_languages", "globalize_translations"]
      ActiveRecord::Base.establish_connection
      (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
        i = "000"
        File.open("#{RAILS_ROOT}/vendor/plugins/bagel/db/demo_data/#{table_name}.yml" , 'w' ) do |file|
          data = ActiveRecord::Base.connection.select_all(sql % table_name)
          file.write data.inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
        end
      end
    end
    
    desc 'Truncate all tables in the current database (WARNING! RED ALERT, THINK BEFORE USING)'
    task :empty => :environment do 
      sql = "TRUNCATE %s"
      skip_tables = ["schema_info","plugin_schema_info", "globalize_countries", "globalize_languages", "globalize_translations" ]
      ActiveRecord::Base.establish_connection
      (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
        ActiveRecord::Base.connection.execute(sql % table_name)
      end
    end
    
    desc 'Load data from db/demo_data in the current database (WARNING! RED ALERT, THINK BEFORE USING)'
    task :load => :environment do
      require 'active_record/fixtures'
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
      (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'vendor', 'plugins', 'bagel', 'db', 'demo_data', '*.{yml,csv}'))).each do |fixture_file|
        Fixtures.create_fixtures(File.join(RAILS_ROOT, 'vendor', 'plugins', 'bagel', 'db', 'demo_data'), File.basename(fixture_file, '.*'))
      end
    end
    
    desc 'Helper task that does db:empty and db:load (WARNING! RED ALERT, THINK BEFORE USING)'
    task :reset => :environment do 
      %w(bagel:db:empty bagel:db:load).each { |t| Rake::Task[t].execute }
    end
    
  end
  
end
