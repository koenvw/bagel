class Admin::WebsitesController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_websites_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @websites_pages, @websites = paginate :website, :per_page => 100, :order => "name"
  end

  def edit
    @website = Website.find_by_id(params[:id]) || Website.new
    if request.post?
      @website.attributes = params[:website]
      if @website.save
        flash[:notice] ='website was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    Website.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
