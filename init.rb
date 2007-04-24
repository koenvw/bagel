# Include hook code here
#

# core extensions
require 'core_extensions.rb'

# Application.rb
require 'bagel_application'
ActionController::Base.send(:include, BagelApplication)


# patches for routing
require 'routing/routing'
#require 'action_controller/routing'
ActionController::Routing::RouteSet.send(:include, Bagel::Routing::RouteSetExtensions)
ActionController::Routing::Route.send(:include, Bagel::Routing::RouteExtensions)
require 'routing/dynamic_routes'

# Authorization
require 'authorization.rb'
ActionController::Base.send(:include, Authorization)

# userstamp
require 'userstamp'
ActionController::Base.send(:before_filter, Proc.new { |c| AdminUser.current_user = AdminUser.find(c.session[:admin_user]) unless c.session[:admin_user].nil? })
ActiveRecord::Base.send(:include, ActiveRecord::Userstamp)
ActiveRecord::Base.relates_to_user_in(:admin_users)

# ActsAsContentType
ActiveRecord::Base.send(:include, ActsAsContentType)

# patches for memcache-client
require 'memcache-client_extentions'

# ActsAsEnhancedNestedSet
require 'acts_as_enhanced_nested_set'
ActiveRecord::Base.send(:include, ActsAsEnhancedNestedSet)

# CalendarHelper
require 'calendar_helper'
ActionView::Base.send(:include, ActionView::Helpers::CalendarHelper)

# TinyMCE
require 'tiny_mce'
TinyMCE::OptionValidator.load
ActionController::Base.send(:include, TinyMCE)

# Application
require 'tiny_mce'
ActionController::Base.send(:include, BagelApplication)
