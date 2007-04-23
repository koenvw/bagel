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
      @gallery.prepare_sitems(params[:sitems], params[:sitems_new])
      if @gallery.save
        @gallery.save_tags(params["tags"])
        @gallery.save_relationships(params["relationsout_id"],params["relationsout_cat_id"],params["relsout_del_id"],params["relsout_del_cat_id"],true)
        @gallery.save_relationships(params["relationsin_id"],params["relationsin_cat_id"],params["relsin_del_id"],params["relsin_del_cat_id"])
        @gallery.set_updated_by(params)
        flash[:notice] = 'Gallery was successfully updated.'
        if params[:redirect]
          redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
        else
          redirect_to :controller => "content", :action => 'list'
        end
      end
    end
  end

  def destroy
    gallery=Gallery.find(params[:id])
    gallery.sobject.relations_as_from.destroy_all
    gallery.destroy
    if params[:redirect]
      redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
    else
      redirect_to :controller => "content", :action => 'list'
    end
  end
end
