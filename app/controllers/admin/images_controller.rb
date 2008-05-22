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
        condition_string = "cached_tag_ids LIKE '%;#{params[:tag_id].to_i};%'"
      else
        condition_string = "cached_tag_ids NOT LIKE '%;#{params[:tag_id].to_i};%'"
      end
    else
      condition_string = "1"
    end
    if params[:search_string]
      condition_string = "1=1 "
      params[:search_string].split(" ").each do |keyword|
        condition_string << " AND (images.title LIKE '%#{ActiveRecord::Base.connection.quote_string(keyword)}%' OR images.image LIKE '%#{ActiveRecord::Base.connection.quote_string(keyword)}%')"
      end
    end
    @image_pages, @images = paginate :image, :per_page => 20, :order => "images.updated_on DESC", :include => :sobject, :conditions => condition_string
  end

  def edit
    @image = Image.find_by_id(params[:id]) || Image.new
    @image.type_id ||= params[:type_id]
    @image.create_default_sitems
 
    @image_versions = []
    versions = Setting.get("versions")
    @image_versions = versions.collect{|k,v| k.to_s}  if versions
    if request.post?
      @image.attributes = params[:image]
      @image.prepare_sitems(params[:sitems])
      @image.title = @image.image_file if @image.title.blank?
      
      @image.save(false)
      
      @image.save_workflow(params[:workflow_steps])
      @image.save_tags(params[:tags])
      @image.save_relations(params[:relations])
      @image.save_comment(params[:newcomment])
      @image.set_updated_by(params)
      
      if @image.save
        flash[:notice] = 'Image was successfully updated.'
        redirect_to params[:referer] || {:controller => "content", :action => "list"}
      end
    end
  end
  
  def update_edited_image
    image = Image.find_by_id(params[:id])
    #first resize
    imagelocation = RAILS_ROOT+"/public/assets/"+image.created_on.year.to_s + image.created_on.month.to_s.rjust(2,"0") +"/#{image.id.to_s}/"+image.image_file
    img_orig = Magick::Image.read(imagelocation).first
    img = img_orig.resize_to_fit(params[:newwidth],params[:newheight])
    img.write(imagelocation)
    image.update_attributes(:height=>params[:newheight],:width=>params[:newwidth])
    #then crop
    if params[:crop_x]
      img_orig = Magick::Image.read(imagelocation).first
      img = img_orig.crop(params[:crop_x].to_i,params[:crop_y].to_i,params[:crop_width].to_i,params[:crop_height].to_i);
      img.write(imagelocation)
    end
    @response.headers["Content-type"] = img.mime_type
    render :text => img.to_blob
  end

  def destroy
    Image.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end

end
