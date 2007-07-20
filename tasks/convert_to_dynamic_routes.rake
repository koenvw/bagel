namespace :bagel do

  namespace :util do

    desc 'Reads routes from config/routes.rb and converts them to dynamic routes. (remove the converted routes from routes.rb after)'
    task :convert_to_dynamic_routes => :environment do

      rs = ActionController::Routing::Routes
      rs.routes.each do |route|
        puts route
        path = route.segments.inject("") { |str,s| str << s.to_s }.chop
        path = "DEFAULT" if path.size == 0
        next if path == "DEFAULT" # this is defined in routes.rb in bagel
        # skip system routes already defined in bagel or rails
		unless ["admin",":site",":controller","show","content","media_item_from_db"].include?(path.split("/")[1])
          urlmap = UrlMapping.find_by_path(path) || UrlMapping.new
          urlmap.path = path
          urlmap.options = route.requirements.to_yaml
          if !urlmap.save
            puts "COULD NOT CONVERT: #{route}\nREASON:#{urlmap.errors}"
          end
        else
          puts "NOT CONVERTED: #{route}\nREASON:system route"
        end
      end

    end

  end
end
