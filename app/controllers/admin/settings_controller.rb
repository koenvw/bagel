class Admin::SettingsController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_settings_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @settings = Setting.find(:all,:order => "lft")
  end

  def new
    # FIXME:
    c = Setting.find(params[:id])
    @setting = Setting.new
    @setting.parent_id = c.id
    params[:position_new] = c.position + 1
    render :controller => 'settings', :action => 'edit'
  end

  def edit
    @setting = Setting.find_by_id(params[:id]) || Setting.new
    if request.post?
      @setting.attributes = params[:setting]
      if @setting.save
        @setting.to_child_of(params[:parent_id])
        flash[:notice] = 'Setting was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    Setting.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def sort
    Setting.find(:all).each do |setting|
      setting.position = params["sortlist"].index(setting.id.to_s) + 1
      setting.save
    end
    render :nothing => true
  end

end
