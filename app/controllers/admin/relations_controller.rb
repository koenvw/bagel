class Admin::RelationsController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_relations_management,:_admin_management]
  layout "application", :only => [:index,:list,:edit,:destroy]
  helper "admin/forms"
  
  uses_tiny_mce tinymce_options
  
  def index
    list
    render :action => 'list'
  end

  # for permissions
  def popup_content
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @relations_pages, @relations = paginate :relation, :per_page => 100, :order => "name"
  end

  def edit
    @relation = Relation.find_by_id(params[:id]) || Relation.new
    if request.post?
      @relation.attributes = params[:relation]
      if @relation.save
        flash[:notice] ='relation was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    Relation.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

end
