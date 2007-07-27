class Admin::AdminRolesController < ApplicationController
  requires_authorization :actions => [:index, :show, :new, :edit, :create, :update, :destroy],
                         :permission => [:admin_roles_management,:_admin_management]

  def index
    @roles = AdminRole.find(:all, :order=>"name")
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
      # Log
      bagel_log :message    => "Admin role created",
                :kind       => 'data',
                :severity   => :low,
                :extra_info => { :role => @role }

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

    old_attributes = {
      :role             => @role.attributes,
      :role_users       => @role.admin_users.map(&:id),
      :role_permissions => @role.admin_permissions.map(&:id),
    }

    if @role.update_attributes(params[:role])
      # Log
      new_attributes = {
        :role             => @role.attributes,
        :role_users       => @role.admin_users.map(&:id),
        :role_permissions => @role.admin_permissions.map(&:id)
      }
      diff = old_attributes.inspect_with_newlines.html_diff_with(new_attributes.inspect_with_newlines)
      bagel_log :message    => "Admin role updated",
                :kind       => 'data',
                :severity   => :low,
                :extra_info => { :diff => diff, :role => @role }

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
