class Admin::ContentTypesController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_content_types_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @types_pages, @types = paginate :content_type, :per_page => 100, :order => "name"
  end

  def edit
    @type = ContentType.find_by_id(params[:id]) || ContentType.new
    if request.post?
      @type.attributes = params[:type]
      if @type.save
        flash[:notice] ='content type was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    ContentType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

end
