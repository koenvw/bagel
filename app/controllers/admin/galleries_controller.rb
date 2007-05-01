class Admin::GalleriesController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_gallery_management,:_content_management]

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :edit }

  def edit
    @gallery = Gallery.find(params[:id]) || Gallery.new
    if request.post?
      @gallery.attributes = params[:gallery]
      @gallery.prepare_sitems(params[:sitems])

      Gallery.transaction do
        if @gallery.save
          @gallery.save_tags(params[:tags])
          @gallery.save_relations(params[:relations])
          @gallery.set_updated_by(params)
          flash[:notice] = 'Gallery was successfully updated.'
          redirect_to params[:referer] || {:controller => "content", :action => "list"}
        end
      end
    end
  end

  def destroy
    gallery=Gallery.find(params[:id])
    gallery.sobject.relations_as_from.destroy_all
    gallery.destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end
end
