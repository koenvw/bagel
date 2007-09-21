# Include hook code here

# Core extensions
require 'core_extensions.rb'

# Application
require 'bagel_application'
ActionController::Base.send(:include, BagelApplication)

# Patches for routing
require 'routing/routing'
require 'routing/routing_from_bagel'
require 'routing/dynamic_routes'
ActionController::Routing::RouteSet.send(:include, Bagel::Routing::RouteSetExtensions)
ActionController::Routing::Route.send(:include, Bagel::Routing::RouteExtensions)
ActionController::Routing::RouteSet::Mapper.send(:include, Bagel::Routing::FromBagel)

# Authorization
require 'authorization.rb'
ActionController::Base.send(:include, Authorization)

# Userstamp
require 'userstamp'
ActionController::Base.send(:before_filter, Proc.new { |c| AdminUser.current_user = (c.session[:admin_user] ? AdminUser.find(c.session[:admin_user]) : nil) })
ActiveRecord::Base.send(:include, ActiveRecord::Userstamp)
ActiveRecord::Base.relates_to_user_in(:admin_users)

# ActsAsContentType
ActiveRecord::Base.send(:include, ActsAsContentType)

# Patches for memcache-client
require 'memcache-client_extentions'

# ActsAsEnhancedNestedSet
require 'acts_as_enhanced_nested_set'
ActiveRecord::Base.send(:include, ActsAsEnhancedNestedSet)

# ActsAsPicture and FileCompat
require 'acts_as_picture'
require 'file_compat'
ActiveRecord::Base.send(:include, ActsAsPicture)

# ActsAsAssistant
require 'acts_as_assistant'
ActionController::Base.send(:include, ActsAsAssistant)

# CalendarHelper
require 'calendar_helper'
ActionView::Base.send(:include, ActionView::Helpers::CalendarHelper)

# TinyMCE
require 'tiny_mce'
TinyMCE::OptionValidator.load
ActionController::Base.send(:include, TinyMCE)

# Liquid
require 'liquid/drops'
require 'liquid/filters'
require 'liquid/cache_tag'
require 'liquid/include_template_tag'
require 'liquid/misc'

# Diff
require 'string_diff'
require 'inspect_with_newlines'

# i can has delishuz
require 'delicious'

# flickr
require 'open-uri'
require 'flickr'
