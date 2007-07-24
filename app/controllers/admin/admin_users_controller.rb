# NOTE: Login/logout now happens in Admin::HomeController instead

class Admin::AdminUsersController < ApplicationController
  requires_authorization :actions => [:index, :show, :edit, :update, :create, :new, :destroy ],
                         :permission => [:admin_users_management,:_admin_management]

  def index
    @admin_users = AdminUser.find(:all, :order => "username")
  end

  def show
    @admin_user = AdminUser.find(params[:id])
  end

  def new
    @admin_user = AdminUser.new
  end

  def edit
    @admin_user = AdminUser.find(params[:id])
  end

  def create
    @admin_user = AdminUser.new(params[:admin_user])
    
    # Set password
    if params[:password].blank?
      flash[:warning] = 'This user needs a passsword!'
      render :action => 'new'
      return
    end
    @admin_user.password = params[:password]

    if @admin_user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to admin_users_url
    else
      render :action => 'new'
    end
  end

  def update
    @admin_user = AdminUser.find(params[:id])
    return if @admin_user.nil?

    # initialize roles if empty (zero checkboxes selected)
    params[:admin_user][:admin_role_ids] ||= []

    # Prevent admin user from being disabled
    if params[:admin_user][:is_active] == '0' and @admin_user.username == 'admin'
      params[:admin_user][:is_active] = true
      flash[:warning] = 'The admin user cannot be disabled.'
    end

    if @admin_user.update_attributes(params[:admin_user])
      @admin_user.password = params[:password] unless params[:password].blank?
      @admin_user.is_active = params[:admin_user][:is_active]
      @admin_user.save
      flash[:notice] = 'User was successfully updated.'
      redirect_to admin_users_url
    else
      render :action => "edit"
    end
  end

  def destroy
    @admin_user = AdminUser.find(params[:id])
    return if @admin_user.nil?
    
    begin
      @admin_user.destroy
    rescue
      flash[:error] = 'The admin user cannot be deleted.'
    end

    redirect_to admin_users_url
  end

end
