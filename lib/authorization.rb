module Authorization
  
  def self.append_features(base)
    super
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
    end
  end
  
  module ClassMethods
  
    # Sets the permissions required for the specified actions
    # you can specify actions and permissions like this:
    # require_authorization :actions => [:edit,:destroy], :permission => :can_edit_and_destroy_stuff
    # actions and permissions can be a symbol or an array of symbols
    # when multiple permissions are given (an array) a user is authorized when he has access to at least 1 of the permissions (OR relation, not AND)
    # controller actions not listed in :actions are accessible by any user
    # permissions must be synched using the rake task "bagel:db:sync_permissions"
    def requires_authorization(a_params)
      # Parse params
      permissions = ([ a_params[:permission] ] + [ a_params[:permissions] ]).flatten.compact
      actions = ([ a_params[:action] ] + [ a_params[:actions] ]).flatten.compact
      
      actions.each do |action|
        requires_authorization_multiple(action, permissions)
      end

    end
    
    # used by the task "bagel:db:sync_permissions"
    def permission_scheme
      # Get the permission scheme class variable
      class_variables.include?('@@permission_scheme') ? class_variable_get(:@@permission_scheme) : {}
    end
    
    private
    def requires_authorization_multiple(a_action, a_permissions)
      # Add pair to class
      a_permissions.each do |permission|
        add_action_permission_pair(a_action, permission)
      end
      
      # Add before filter
      before_filter :only => a_action do |controller|
        controller.require_authorization(a_permissions)
      end
    end
    
    def add_action_permission_pair(a_action, a_permission)
      old_permission_scheme = permission_scheme
      
      # Determine new permission scheme
      permissions_for_action = old_permission_scheme[a_action] || []
      permissions_for_action << a_permission
      permissions_for_action.uniq!
      new_permission_scheme = old_permission_scheme.merge(a_action => permissions_for_action)
      
      # Set new permission scheme
      class_variable_set(:@@permission_scheme, new_permission_scheme)
    end
    
  end
  
  module InstanceMethods
    
    def require_authorization(a_permissions)
      is_authorized = false
      a_permissions.each do |permission|
        if not AdminUser.current_user.nil? and AdminUser.current_user.has_admin_permission?(permission)
          is_authorized = true
        end
      end

      unless is_authorized
        flash.now[:error] = 'You are not authorized to view the page you requested.'
        # we check request.env first because request.referer does not exists if no referer
        # if the referer is not the current request_uri be redirect the user back
        if !request.env["HTTP_REFERER"].nil? && request.referer != "#{request.protocol}#{request.host_with_port}#{request.request_uri}"
          redirect_to :back
        else
          redirect_to admin_me_url
        end
        return false
      end
    end
    
  end
  
end
