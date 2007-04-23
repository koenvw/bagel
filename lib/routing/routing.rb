module Bagel #:nodoc:
  # source: http://weblog.jamisbuck.org/2006/10/26/monkey-patching-rails-extending-routes-2
  module Routing

    module RouteExtensions #:nodoc:
      def self.included(base)
        base.alias_method_chain :recognition_conditions, :host
      end

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
