class Admin::TagsController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:content_tags_management,:_content_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    # Order categories by lft to make them faster to display
    @tags = Tag.find(:all, :order => 'lft ASC')
  end

  def edit
    @tag = Tag.find_by_id(params[:id]) || Tag.new
    if request.post?
      @tag.attributes = params[:tag]
      if @tag.save
        @tag.to_child_of(params[:parent_id])
        flash[:notice] = 'Tag was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    Tag.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def sort_children
    @tag = Tag.find(params[:id])
    @tag.sort_children
    redirect_to :action => 'list'
  end

end

