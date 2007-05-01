module Bagel #:nodoc:
  module Routing #:nodoc:

    module RouteExtensions 
      def self.included(base) #:nodoc:
        base.alias_method_chain :recognition_conditions, :host
      end

      # Source: http://weblog.jamisbuck.org/2006/10/26/monkey-patching-rails-extending-routes-2.
      #
      # Allows extra conditions in routes:  :host, :domain, :subdomain.
      #   map.connect '/nieuws', :controller => 'site', :action => 'content', :type => 'generator', :id => 'auto55_be_list_nieuws', :site => 'auto55_be', :conditions => {:subdomain => 'www',:domain => 'auto55.be'}
      def recognition_conditions_with_host
        result = recognition_conditions_without_host
        result << "conditions[:host] === env[:host]" if conditions[:host]
        result << "conditions[:domain] === env[:domain]" if conditions[:domain]
        result << "conditions[:subdomain] === env[:subdomain]" if conditions[:subdomain]
        result
      end
    end

    module RouteSetExtensions #:nodoc:
      def self.included(base)
        base.alias_method_chain :extract_request_environment, :host
      end

      def extract_request_environment_with_host(request)
        env = extract_request_environment_without_host(request)
        env.merge :host => request.host,
          :domain => request.domain, :subdomain => request.subdomains.first
      end
    end

  end
end
