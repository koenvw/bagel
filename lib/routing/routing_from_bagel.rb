# lifted this from the engines plugin
# The key method is Bagel::Routing::FromBagel#from_bagel, which can be called
# within your application's <tt>config/routes.rb</tt> file to load plugin routes at that point.
#
module Bagel::Routing::FromBagel
  # Loads the set of routes from within bagel and evaluates them at this
  # point within an application's main <tt>routes.rb</tt> file.
  #
  # Plugin routes are loaded from <tt><plugin_root>/routes.rb</tt>.
  def from_bagel(name)
    routes_as_string = ""
    mappings = UrlMapping.find(:all, :order => "position") rescue
    if mappings 
      mappings.each do |urlmap|
        routes_as_string << "connect '#{urlmap.path}', #{YAML.load(urlmap.options).inspect}\n"
      end
      # FIXME: evaluating untrusted input!
      eval(routes_as_string, binding) unless routes_as_string.blank?
    end
  end
end
