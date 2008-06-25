require 'RMagick'

class Admin::MediaItemsController < ApplicationController

  requires_authorization :actions    => [ :index, :list, :edit, :destroy ],
                         :permission => [ :content_images_management,:_content_management ]

  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  helper "admin/forms"

  def index
    list
    render :action => 'list'
  end

  def list
    # Skip thumbnails
    condition_string = 'type LIKE \'Picture%\' AND parent_id IS NULL'

    # Find by search string
    if params[:search_string]
       escaped_search_string = ActiveRecord::Base.connection.quote_string(params[:search_string])

       condition_string += " AND ("
       condition_string += "      media_items.title       LIKE '%#{escaped_search_string}%'"
       condition_string += "   OR media_items.filename    LIKE '%#{escaped_search_string}%'"
       condition_string += "   OR media_items.description LIKE '%#{escaped_search_string}%'"
       condition_string += " )"
    end

    # Find all media
    @media_item_pages, @media_items = paginate_collection MediaItem.find(:all, :conditions => condition_string, :order => "media_items.updated_on DESC", :include => :sobject),
                                                          :per_page   => 20,
                                                          :page => params[:page]

    # Determine count
    @media_items_filtered_count = @media_items.length
    @media_items_count          = MediaItem.find(:all, :conditions => 'type LIKE \'Picture%\' AND parent_id IS NULL').length
  end
  
  
  def update_edited_image
    media_item = MediaItem.find_by_id(params[:id])
    logger.info(media_item.public_filename)
    #first resize
    img_orig = Magick::Image.read(RAILS_ROOT+'/public'+ media_item.public_filename).first
    img = img_orig.resize_to_fit(params[:newwidth],params[:newheight])
    img.write(RAILS_ROOT+'/public/'+ media_item.public_filename)
    media_item.update_attributes(:height=>params[:newheight],:width=>params[:newwidth])
    #then crop
    if params[:crop_x]
      img_orig = Magick::Image.read(RAILS_ROOT+'/public/'+ media_item.public_filename).first
      img = img_orig.crop(params[:crop_x].to_i,params[:crop_y].to_i,params[:crop_width].to_i,params[:crop_height].to_i);
      img.write(RAILS_ROOT+'/public/'+ media_item.public_filename)
    end
    
    @response.headers["Content-type"] = img.mime_type
    render :text => img.to_blob
  end
  

  def edit
    # Find media item
    @media_item = MediaItem.find_by_id(params[:id])

    # Create media item if non-existant
    if @media_item.nil?
      # Make sure we are creating something that is allowed
      unless MediaItem::ALLOWED_CLASS_NAMES.include?(params[:type])
        flash[:error] = 'The type of media item you selected is not valid.'
        redirect_to :action => :list
        return
      end

      # Create a media item of the given class
      case params[:type]
      when 'PictureS3'
        @media_item = PictureS3.new
      when 'PictureFTP'
        @media_item = PictureFTP.new
      when 'PictureFileSystem'
        @media_item = PictureFileSystem.new
      when 'PictureDbFile'
        @media_item = PictureDbFile.new
      end

      @media_item[:type] = params[:type]
    end

    # When requesting a thumbnail, redirect to original
    unless @media_item.parent_id.blank?
      redirect_to :action => 'edit', :id => @media_item.parent_id
      return
    end

    @media_item.type_id ||= params[:type_id]
    @media_item.create_default_sitems

    # Find versions names
    if MediaItem::PICTURE_CLASS_NAMES.include?(@media_item[:type])
      @media_item_versions = Setting.image_versions.collect { |k,v| k.to_s }
    end

    if request.post?
      @media_item.attributes = params[:media_item]
      @media_item.prepare_sitems(params[:sitems])

      # Give a pretty title to this media item
      @media_item.set_title

      begin
        @media_item.save(false)
        @media_item.save_workflow(params[:workflow_steps])
        @media_item.save_tags(params[:tags])
        @media_item.save_relations(params[:relations])
        @media_item.save_comment(params[:newcomment])

        @media_item.set_updated_by(params)

        if @media_item.save
          flash[:notice] = 'Media item was successfully updated.'
          redirect_to :controller => 'media_items', :action => 'edit', :id => @media_item
        end
      rescue => e
        flash[:error] = %[An unexpected error occurred while trying to save the media item: "#{e.to_s}".]
        bagel_log :exception => e, :severity => :high, :kind => 'exception'
      end
    end
  end

  def destroy
    MediaItem.find(params[:id]).destroy
    flash[:notice] = 'Media item was successfully deleted.'
    redirect_to :back
  end

end
