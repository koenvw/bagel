class Admin::HomeController < ApplicationController
  requires_authorization :actions => [:admin], :permission => [:_main_menu_admin]
  requires_authorization :actions => [:index], :permission => [:_main_menu_content]
  requires_authorization :actions => [:webfolder], :permission => [:_main_menu_webfolder]

  def login
    if not AdminUser.current_user.nil?
      # Already logged in
      redirect_to :controller => '/admin'
    elsif request.post?
      if params[:login]
        # User wants to log in
        handle_login
      elsif params[:reset_password]
        # User wants to reset password
        handle_login_reset_password
      end
    else
      render :layout => false
    end
  end

  def logout
    session[:admin_user] = nil
    redirect_to :controller => 'admin/home', :action => 'login'
  end

  def reset_password
    # Find user
    user = AdminUser.find_by_username(params[:username])

    # Get codes
    given_code  = params[:code]
    stored_code = user.nil? ? nil : user.password_code

    # Compare codes
    if user.nil? or given_code.nil? or given_code != stored_code
      render :action => 'reset_password_failure', :layout => false
      return
    end

    if request.post?
      # Check password
      if params[:new_password] != params[:new_password_confirmation]
        flash[:notice] = 'The two passwords you entered do not match.'
        render :layout => false
        return
      end

      # Change password
      user.password = params[:new_password]
      user.password_code = nil
      user.save

      # Redirect to login form
      flash[:notice] = 'Your password has been reset.'
      redirect_to login_url
      return
    else
      render :layout => false
    end
  end

  def index
    #FIXME: how to exclude certains content types / tags
    types = ContentType.find(:all).reject {|type| type.extra_info == "hide"}.map {|type| type.id}
    @recent_items = Sobject.find_with_parameters(:status => :all,
                                                 :content_types => types,
                                                 :limit=> 10,
                                                 :order => "sobjects.updated_on DESC")
  end

  def redirect_to_home
    # Redirect user to his admin homepage
    if AdminUser.current_user.has_admin_permission?(:_main_menu_content)
      allowed_page = '/admin/home/index'
    else
      allowed_page = '/admin/me'
    end
    redirect_to allowed_page
  end

  def webfolder
    # Find root path
    root_path = RAILS_ROOT + Setting.get_cached('WebFolderSettings')[:root_path] || '/public/filestorage/'
    FileUtils.mkdir root_path unless File.exists?(root_path)

    # Find all entries in the web folder
    @dir_entries = Dir.entries(root_path)
    @dir_entries.reject!  { |entry| entry.begins_with?('.') or entry == '_imported' }
    @dir_entries.collect! { |entry| root_path + entry }

    # Find all possible content types
    @content_types_arr = ContentType.find_all_by_core_content_type('MediaItem')
    @content_types = @content_types_arr.map { |i| "<option value=\"#{i.id}\">#{i.name}</option>" }.join

    # Find all possible relationships (from MediaItem to Container)
    @relations_arr = Relation.find(:all)
    @relations_arr.reject! { |r| r.content_types.select { |c| c.core_content_type == 'MediaItem' }.empty? }
    @relations_arr.reject! { |r| r.content_type.core_content_type != 'Container' }
    @relations = @relations_arr.map { |i| "<option value=\"#{i.id}\">#{i.name}</option>" }.join
  end

private

  def handle_login
    # Require username and password
    if params[:admin_user][:username].blank? or params[:admin_user][:password].blank?
      flash[:notice] = 'Please enter your username and password.'
      render :layout => false
      return
    end
    
    # Attempt to authenticate user
    user = AdminUser.authenticate(params[:admin_user][:username], params[:admin_user][:password])
    if user.nil? or not user.is_active?
      flash[:notice] = 'Incorrect username or password.'
      render :layout => false
      return
    end

    # Log the user in
    session[:admin_user] = user.id

    # Redirect to requested page
    requested_page = session[:requested_page] || { :controller => '/admin/home', :action => "index" }
    redirect_to requested_page
  end


  def handle_login_reset_password
    # Require username
    if params[:admin_user][:username].blank?
      flash[:notice] = 'Please enter your username.'
      render :layout => false
      return
    end

    # Find user
    user = AdminUser.find_by_username(params[:admin_user][:username])
    if user.nil? or not user.is_active?
      # Pretend to have sent password reset instructions
      # (so people can't figure out whether a given username exists)
      flash[:notice] = 'Password reset instructions has been sent.'
      render :layout => false
      return
    end

    # Create a password code
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    password_code = ''
    20.times { password_code << chars[rand(chars.size-1)] }
    user.password_code = password_code
    user.save

    # Send mail
    AdminUserMailer.deliver_password_reset(user, request.env['SERVER_NAME'])

    flash[:notice] = 'Password reset instructions has been sent.'
    render :layout => false
  end

end
