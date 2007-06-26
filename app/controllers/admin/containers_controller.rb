class Admin::ContainersController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_container_management,:_content_management]
  uses_tiny_mce tinymce_options

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  def edit
    @container = Container.find_by_id(params[:id]) || Container.new
    @container.type_id ||= params[:type_id]
    if request.post?
      @container.attributes = params[:container]
      @container.prepare_sitems(params[:sitems])
      Container.transaction do
        if @container.save
          @container.save_workflow(params[:workflow_steps])
          @container.save_tags(params[:tags])
          @container.save_relations(params[:relations])
          @container.set_updated_by(params)
          flash[:notice] ='Container was successfully updated.'
          redirect_to params[:referer] || {:controller => "content", :action => "list"}
        end
      end
    end
  end

  def destroy
    Container.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end
end
