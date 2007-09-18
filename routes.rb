# ROOT

connect '',      :controller => 'site',       :action => 'root'
connect 'admin', :controller => 'admin/home', :action => 'redirect_to_home'

# SPECIAL CASES

connect '/media_item_from_db', :controller => 'site', :action => 'media_item_from_db'

# ADMIN

with_options :controller => 'admin/home' do |m|
  m.login          '/admin/login',                    :action => 'login'
  m.logout         '/admin/logout',                   :action => 'logout'
  m.reset_password '/admin/reset_password/:username', :action => 'reset_password', :username => nil
end

with_options :controller => 'admin/me' do |m|
  m.admin_me             '/admin/me/:action', :action => 'show'
  m.change_email_address '/admin/me/change_email_address'
end

with_options :controller => 'admin/admin_users' do |m|
  m.admin_user  '/admin/users/:id/:action', :action => 'show', :requirements => { :id => /[1-9][0-9]*/ }
  m.admin_users '/admin/users/:action'
end

with_options :controller => 'admin/admin_roles' do |m|
  m.admin_role  '/admin/roles/:id/:action', :action => 'show', :requirements => { :id => /[1-9][0-9]*/ }
  m.admin_roles '/admin/roles/:action'
end

with_options :controller => 'admin/urlmappings' do |m|
  m.admin_urlmappings '/admin/urlmappings'
end

with_options :controller => 'admin/log_messages' do |m|
  m.admin_log_messages        '/admin/log_messages'
  m.admin_log_messages_rotate '/admin/log_messages/rotate',      :action => 'rotate'
  m.admin_log_message         '/admin/log_messages/:id/:action', :action => 'show'
end

with_options :controller => 'admin/translations' do |m|
  m.admin_translations            '/admin/translations'
  m.admin_translations_translate  '/admin/translations/:id',  :action => 'translate'
end

# ANY DOMAIN

connect '/:site/index',                   :controller => 'site', :action => 'index'
connect '/:site/show/:type/:id',          :controller => 'site', :action => 'content'
connect '/:site/show/:type/:id.:format',  :controller => 'site', :action => 'content'
connect '/:site/show/:type/:id/:sub_id',  :controller => 'site', :action => 'content'

# VIRTUAL DOMAINS

connect '/show/:type/:id',                :controller => 'site', :action => 'content'
connect '/show/:type/:id.:format',        :controller => 'site', :action => 'content'
connect '/content/:type/:id',             :controller => 'site', :action => 'content'
connect '/content/:type/:id.:format',     :controller => 'site', :action => 'content'
