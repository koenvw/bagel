# ROOT
  connect '', :controller => 'site', :action => 'root'
  
  # ADMIN
  with_options :controller => 'admin/home' do |m|
    m.login          '/admin/login',                    :action => 'login'
    m.logout         '/admin/logout',                   :action => 'logout'
    m.reset_password '/admin/reset_password/:username', :action => 'reset_password', :username => nil
    m.admin          '/admin'
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
  
  # ANY DOMAIN
  connect '/:site/index',                   :controller => 'site', :action => 'index'
  connect '/:site/show/:type/:id',         :controller => 'site', :action => 'content'
  connect '/:site/show/:type/:id.:format',         :controller => 'site', :action => 'content'
  connect '/:site/show/:type/:id/:sub_id',  :controller => 'site', :action => 'content'

  # VIRTUAL DOMAINS
  connect '/show/:type/:id',   :controller => 'site', :action => 'content'
  connect '/show/:type/:id.:format',   :controller => 'site', :action => 'content'
  connect '/content/:type/:id', :controller => 'site', :action => 'content'
  connect '/content/:type/:id.:format', :controller => 'site', :action => 'content'
  
  