class Admin::LinksController < ApplicationController
  uses_tiny_mce tinymce_options

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @link_pages, @links = paginate :link, :per_page => 10, :order => "created_on DESC"
  end

  def edit
    if params[:id].nil?
      @link = Link.new
    else
      @link = Link.find(params[:id])
    end
    if request.post?
      @link.attributes = params[:link]
      @link.prepare_sitems(params[:sitems], params[:sitems_new])
      if @link.save
        @link.save_tags(params[:tags])
        @link.save_relationships(params["relationsout_id"],params["relationsout_cat_id"],params["relsout_del_id"],params["relsout_del_cat_id"],true)
        @link.save_relationships(params["relationsin_id"],params["relationsin_cat_id"],params["relsin_del_id"],params["relsin_del_cat_id"])
        @link.set_updated_by(params)
        flash[:notice] ='Link was successfully updated.'
        redirect_to :controller => "content", :action => 'list', :content_type => "link"
      end
    end
  end

  def destroy
    Link.find(params[:id]).destroy
    redirect_to :controller => "content", :action => 'list', :content_type => "link"
  end

  def approve
    if request.post?
      links_present=Array.new
      llinks=Array.new
      llink=Array.new
      i=0
      unless params[:link].nil?
        for field in params[:link]
          i+=1
          llink<<field
          if i==4
            llinks<<llink
            llink=Array.new
            i=0
          end
        end
        for dlink in llinks
          links_present<<dlink[0]
          @link=Link.find(dlink[0])
          @link.title=dlink[1]
          @link.url=dlink[2]

          if dlink[3].to_i>0
            @link.tags.delete_all
            @link.add_tag_unless(Category.find(dlink[3]))
          end
          @sitem=@link.sitems.find_by_website_id(params[:site_id])
          @sitem.status="1"
          @sitem.save
          @link.save
        end
      end
      for dellink in params[:dellinks]
        if links_present.find{|r| r==dellink}.nil?
          Link.find(dellink).destroy
        end
      end
      redirect_to :controller => "content", :action => 'list', :content_type => "link"
    end
  end
end
