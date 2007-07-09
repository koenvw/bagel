module ActionController #:nodoc:
  module Routing #:nodoc:
    class RouteSet
      # Routing monkey-patch. recognize_path is taken from rails core.
      # http://dev.rubyonrails.org/browser/trunk/actionpack/lib/action_controller/routing.rb
      # justification: we need to intercept the rails route recognition process. 
      # when no route from config/routes.rb is found, we should try the database and add routes on the fly
      # see http://weblog.jamisbuck.org/2006/10/2/under-the-hood-rails-routing-dsl
      # end http://weblog.jamisbuck.org/2006/10/4/under-the-hood-route-recognition-in-rails # for more information
      def recognize_path(path, environment={})
        # this is standard rails
        path = CGI.unescape(path)
        routes.each do |route|
          result = route.recognize(path, environment) and return result
        end
        # this is ours. check for dynamic routes
        # FIXME: is UrlMapping.find(:all) cached ? if not, non-existing route will result in db-queries?!
        UrlMapping.find(:all, :order => "position").each do |urlmap|
          # construct a Route object for our urlmapping
          route = ActionController::Routing::Routes.builder.build(urlmap.path,YAML.load(urlmap.options))
          # if the route is recognized we add it to our internal routes list and return the result
          # next time the route will not have to be build and recognized here.
          # doing things this way is exactly the same as if our route was defined through config/routes.rb
          result = route.recognize(path, environment) and add_route_with_a_vengeance(route) and return result
        end 
        # nothing found, bail out...
        # FIXME: why does exception_notification plugin send an error mail on all 404's? (everything that is not a controller/action)
        # tempfix -> raise ActiveRecord::RecordNotFound
        raise ActiveRecord::RecordNotFound, "no route found to match #{path.inspect} with #{environment.inspect}"
      end
      # add a route to the list in last-but-one position
      # we assume that the last route is the default one (:controller/:action/:id)
      def add_route_with_a_vengeance(route) #:nodoc:
        last_route = routes.pop
        raise "the default route is not the last route in config/routes.rb" unless last_route.to_s == "ANY    /:controller/:action/:id/                {}"
        routes << route << last_route
      end
    end
  end
end
