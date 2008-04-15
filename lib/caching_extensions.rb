# monkey-patch Page Caching (backported from rails 2.0.2)
# this code uses request.path instead of url_for if when no options given
# also looks at bagel settings to decide to cache or not
module ActionController::Caching
  module Pages
    module ClassMethods
      def bagel_caches_page(*actions)
        return unless perform_caching
        actions.each do |action|
          class_eval "after_filter { |c| c.bagel_cache_page if c.action_name == '#{action}' }"
        end
      end
    end
    # Manually cache the +content+ in the key determined by +options+. If no content is provided, the contents of response.body is used
    # If no options are provided, the requested url is used. Example:
    #   cache_page "I'm the cached content", :controller => "lists", :action => "show"
    def bagel_cache_page(content = nil, options = nil)
      return unless perform_caching && caching_allowed && AppConfig[:cache_to_filesytem]

      path = case options
        when Hash
          url_for(options.merge(:only_path => true, :skip_relative_url_root => true, :format => params[:format]))
        when String
          options
        else
          request.path
      end

      self.class.cache_page(content || response.body, path)
    end
  end
end
