class Admin::SiteUsersController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_site_users_management,:_content_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @site_user_pages, @site_users = paginate :site_user, :per_page => 25, :order => "site_users.created_on DESC", :include => :sobject
  end

  def edit
    @site_user = SiteUser.find_by_id(params[:id]) || SiteUser.new
    @site_user.type_id ||= params[:type_id]
    @site_user.create_default_sitems
    if request.post?
      @site_user.attributes = params[:site_user]
      @site_user.prepare_sitems(params[:sitems])
      if @site_user.save
        @site_user.save_tags(params[:tags])
        @site_user.save_relations(params[:relations])
        @site_user.save_comment(params[:newcomment])
        flash[:notice] = 'SiteUser was successfully updated.'
        redirect_to params[:referer] || {:controller => "content", :action => "list"}
      end
    end
  end

  def destroy
    SiteUser.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end
end
