class Admin::ImagesController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy], :permission => [:content_images_management,:_content_management]

  uses_tiny_mce tinymce_options

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :import_do ], :redirect_to => { :action => :list }

  def list
    unless params[:tag_id].nil?
      params[:tag_id]=params[:tag_id].to_i
      if params[:tag_id]>0
        condition_string = "cached_category_ids LIKE '%;#{params[:tag_id].to_i};%'"
      else
        condition_string = "cached_category_ids NOT LIKE '%;#{params[:tag_id].to_i};%'"
      end
    else
      condition_string = "1"
    end
    if params[:search_string]
       condition_string+=" AND images.title LIKE '%#{params[:search_string].gsub("'","''")}%'"
    end
    @image_pages, @images = paginate :image, :per_page => 20, :order => "images.updated_on DESC", :include => :sobject, :conditions => condition_string
  end

  def edit
    @image = Image.find_by_id(params[:id]) || Image.new
    @image.type_id ||= params[:type_id]
    @image_versions = []
    versions = Setting.get("versions")
    @image_versions = versions.collect{|k,v| k.to_s}  if versions
    if request.post?
      @image.attributes = params[:image]
      @image.prepare_sitems(params[:sitems])
      @image.title = @image.image_file if @image.title.nil_or_empty?
      if @image.save
        @image.save_workflow(params[:workflow_steps])
        @image.save_tags(params[:tags])
        @image.save_relations(params[:relations])
        @image.set_updated_by(params)
        flash[:notice] = 'Image was successfully updated.'
        redirect_to params[:referer] || {:controller => "content", :action => "list"}
      end
    end
  end

  def destroy
    Image.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end

end
