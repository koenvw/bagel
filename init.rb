# Include hook code here

# Liquid
require 'liquid'

# AppConfig
require 'configuration'

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
require 'caching_extensions'

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

# better_nested_set
# (c) 2005 Jean-Christophe Michel
# MIT licence
#
require 'betternestedset/better_nested_set'
require 'betternestedset/better_nested_set_helper'

ActiveRecord::Base.class_eval do
  include SymetrieCom::Acts::NestedSet
end
ActionView::Base.send :include, SymetrieCom::Acts::BetterNestedSetHelper

# plugin init file for rails
# this file will be picked up by rails automatically and
# add the file_column extensions to rails

require 'file_column/file_column'
require 'file_column/file_compat'
require 'file_column/file_column_helper'
require 'file_column/validations'
require 'file_column/test_case'

ActiveRecord::Base.send(:include, FileColumn)
ActionView::Base.send(:include, FileColumnHelper)
ActiveRecord::Base.send(:include, FileColumn::Validations)

