class Admin::PagesController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_page_management,:_content_management]
  uses_tiny_mce tinymce_options

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  def edit
    if params[:id].nil?
      @page = Page.new
    else
      @page = Page.find(params[:id])
    end
    if request.post?
      @page.attributes = params[:page]
      @page.prepare_sitems(params[:sitems], params[:sitems_new])
      if @page.save
        @page.save_tags(params[:tags])
        @page.save_relationships(params["relationsout_id"],params["relationsout_cat_id"],params["relsout_del_id"],params["relsout_del_cat_id"],true)
        @page.save_relationships(params["relationsin_id"],params["relationsin_cat_id"],params["relsin_del_id"],params["relsin_del_cat_id"])
        @page.set_updated_by(params)
        flash[:notice] ='Page was successfully updated.'
        if params[:redirect]
          redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
        else
          redirect_to :controller => 'content', :action => 'list'
        end
      end
    end
  end

  def destroy
    Page.find(params[:id]).destroy
    if params[:redirect]
      redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
    else
      redirect_to :controller => 'content', :action => 'list'
    end
  end

end
