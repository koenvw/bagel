class Admin::AdminRolesController < ApplicationController
  requires_authorization :actions => [:index, :show, :new, :edit, :create, :update, :destroy],
                         :permission => [:admin_roles_management,:_admin_management]

  def index
    @roles = AdminRole.find(:all)
  end

  def show
    @role = AdminRole.find(params[:id])
  end

  def new
    @role = AdminRole.new
  end

  def edit
    @role = AdminRole.find(params[:id])
  end

  def create
    @role = AdminRole.new(params[:role])

    if @role.save
      flash[:notice] = 'Role was successfully created.'
      redirect_to admin_roles_url
    else
      render :action => 'new'
    end
  end

  def update
    @role = AdminRole.find(params[:id])

    # initialize permissions and users if empty (zero checkboxes selected)
    params[:role][:admin_permission_ids] ||= []
    params[:role][:admin_user_ids] ||= []

    if @role.update_attributes(params[:role])
      flash[:notice] = 'Role was successfully updated.'
      redirect_to admin_roles_url
    else
      render :action => "edit"
    end
  end

  def destroy
    @role = AdminRole.find(params[:id])
    @role.destroy

    redirect_to admin_roles_url
  end

end
