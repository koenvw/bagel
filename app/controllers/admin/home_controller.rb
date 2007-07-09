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
    redirect_to "/"
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

  def webfolder
    # setup root_path
    # FIXME: this setting should be in environment.rb
    root_path = RAILS_ROOT + "/public/filestorage/"
    FileUtils.mkdir root_path unless File.exists?(root_path)
    # exclude default dirs
    @dir_entries = Dir.entries(root_path).select { |entry| ![".","..","_imported",".DAV"].include?(entry) }
    # append root_path to entries
    @dir_entries.collect! { |entry| root_path + entry }
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
    requested_page = session[:requested_page] || { :controller => '/admin' }
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
