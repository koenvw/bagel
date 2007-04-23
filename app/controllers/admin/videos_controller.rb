class Admin::VideosController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_video_management,:_content_management]
  uses_tiny_mce tinymce_options

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  def edit
    if params[:id].nil?
      @video = Video.new
    else
      @video = Video.find(params[:id])
    end
    if request.post?
      @video.attributes = params[:video]
      @video.prepare_sitems(params[:sitems], params[:sitems_new])

      if @video.save
        @video.save_tags(params["tags"])
        @video.save_relationships(params["relationsout_id"],params["relationsout_cat_id"],params["relsout_del_id"],params["relsout_del_cat_id"],true)
        @video.save_relationships(params["relationsin_id"],params["relationsin_cat_id"],params["relsin_del_id"],params["relsin_del_cat_id"])
        @video.set_updated_by(params)

        flash[:notice] = 'Video was successfully updated.'

        if params[:book_id] == ""
          if params[:redirect]
            redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
          else
            redirect_to :controller => 'content', :action => 'list', :tag_id => params[:tag_id]
          end
        else
          redirect_to "/admin/videos/edit/#{params[:video_id]}/?video_id=#{@video.id}"
        end
      end
    end
  end

  def destroy
    Video.find(params[:id]).destroy
    if params[:redirect]
      redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
    else
      redirect_to :controller => 'content', :action => 'list', :tag_id => params[:tag_id]
    end
  end
end
