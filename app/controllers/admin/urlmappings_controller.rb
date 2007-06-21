class Admin::UrlmappingsController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_url_mappings_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @urlmappings_pages, @urlmappings = paginate :url_mapping, :per_page => 100, :order => "position"
  end

  def edit
    @urlmapping = UrlMapping.find_by_id(params[:id]) || UrlMapping.new
    if request.post?
      @urlmapping.attributes = params[:urlmapping]
      if @urlmapping.save
        flash[:notice] ='UrlMapping was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    UrlMapping.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def sort
    mappings = UrlMapping.find(:all,:order => "path")
    mappings.each_with_index do |mapping,i|
      mapping.position = i
      mapping.save
    end
    flash[:notice] ='UrlMappings were sorted successfully.'
    redirect_to :action => 'list'
  end

end
