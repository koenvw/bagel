class Admin::DocumentsController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_document_management,:_content_management]
  uses_tiny_mce tinymce_options

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  def edit
    @document = Document.find_by_id(params[:id]) || Document.new
    @document.type_id ||= params[:type_id]
    @document.create_default_sitems
    if request.post?
      @document.attributes = params[:document]
      @document.prepare_sitems(params[:sitems])
      @document.title = @document.filename if @document.title.blank?
      Document.transaction do
        @document.save(false)
        
        @document.save_workflow(params[:workflow_steps])
        @document.save_tags(params["tags"])
        @document.save_relations(params["relations"])
        @document.set_updated_by(params)
        @document.save_comment(params[:newcomment])
        
        if @document.save
          # Share on del.icio.us
          share_on_delicious(@document, params[:sharing_delicious_site]) if params[:sharing_delicious]

          flash[:notice] = 'document was successfully updated.'
          redirect_to params[:referer] || {:controller => "content", :action => "list"}
        end
      end
    end
  end

  def destroy
    Document.find(params[:id]).destroy and redirect_to :back
  end

end
