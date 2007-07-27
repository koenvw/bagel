class Admin::ContentController < ApplicationController
  requires_authorization :actions => [:index,:list,:wizard], :permission => [:_content_management]
  uses_tiny_mce tinymce_options

  def index
    list
    render :action => 'list'
  end

  def list
    includes = nil; conditions = nil; publish_from = nil; publish_till = nil
    publish_date = params[:publish_date]
    if publish_date
      publish_from = params[:publish_date].to_time.at_beginning_of_day
      publish_till = params[:publish_date].to_time.tomorrow.at_beginning_of_day
    end

    @item_pages, @items = paginate_collection Sobject.find_with_parameters(:status => :all,
                                                                           :content_types => params[:type_id],
                                                                           :tags => params[:tag_id],
                                                                           :website_id => params[:website_id],
                                                                           :published_by => params[:user_id],
                                                                           :current_workflow => params[:step_id],
                                                                           :publish_from => publish_from,
                                                                           :publish_till => publish_till,
                                                                           :limit=> 1000,
                                                                           :order => "sitems.publish_date DESC, sobjects.id DESC",
                                                                           :include => includes,
                                                                           :conditions => conditions,
                                                                           :search_string => params[:search_string]),

                                             :page => params[:page],
                                             :per_page => 25
    # FIXME: the condition is necessary because generator is not a real content type
    @content_types = ContentType.find(:all, :conditions => "hidden = 0", :order => "name")
    @websites = Website.find(:all,:order => "name")
  end


  def wizard
    # lookup content types
    @content_types = ContentType.find(:all, :conditions => "extra_info!='hide'", :order => "name") # FIXME: hide via checkbox, not via extra info ?
    #@wizard_content_types = ContentType.find(:all, :conditions => "core_content_type='News'", :order => "name")
    reset_session
  end

  def wizard1
    if request.env['HTTP_USER_AGENT'].match("Firefox")
      flash.now[:notice] = "Warning: this wizard does not currently support Firefox"
    end
    session[:wizard][:images_time] = Time.now
  end

  # IMAGE UPLOAD
  def wizard1_submit
    render :nothing => true and return if AdminUser.current_user.nil?
    # capture incoming file params from flash
    data = params[:Filedata]
    name = params[:Filename]
    if data and name
      # save the image
      @image = Image.create :image => data, :title => name
    end
    # there's no view so render nothing
    render :nothing => true
  end

  # FOTOSPECIAL
  def wizard2
    @images = get_images_from_session
    if @images.empty?
    #    redirect_to :action => "wizard3", :type_id => params[:type_id] and return
    end
  end

  # FOTOSPECIAL
  def wizard2_submit
    if get_images_from_session.empty?
      redirect_to :action => 'wizard3', :type_id => params[:type_id] and return
    end
    if params[:entries].nil? &&
      flash[:error] = "No images selected."
      redirect_to :action => 'wizard2', :type_id => params[:type_id] and return
    end
    #
    @images = get_images_from_session
    # create a gallery
    Container.transaction do
      @gallery = Gallery.create :title => params[:title]
      if @gallery.valid?
        session[:wizard][:gallery_images] ||= []
        ## for each image selected
        params[:entries].each do |entry|
          ### find image in session
          @image = @images.select{|i| i.id.to_s == entry }.first
          ### and set the relation to the gallery
          picture_cat = Relation.find_or_create_by_name('Picture')
          @gallery.sobject.create_in_relations_as_from :to => @image.sobject, :relation => picture_cat
          ###
          session[:wizard][:gallery_images] << @image.id
        end
        # unpublish
        @gallery.sitems.each{|s| s.status = 0; s.save }
        #flash[:notice] = 'Gallery was successfully created.'
        add_to_session(:gallery_id,@gallery.id)
        redirect_to :action => 'wizard3', :type_id => params[:type_id]
      else
        flash[:error] = "Gallery has no name"
        redirect_to :action => 'wizard2', :type_id => params[:type_id] and return
      end
    end
  end

  # CONTENT
  def wizard3
    if session[:wizard][:news_id].nil?
      @news = News.new
    else
      @news = News.find(session[:wizard][:news_id])
    end

    if request.post?
      # some magic voodoo for converting breaklines to paragraphs
      body = params[:news]["body"]
      body.gsub!("<br /><br />","<br />")
      body.gsub!("<br />","</p><p>")
      body = "<p>#{body}" unless body[0..2] == "<p>"
      params[:news]["body"] = body

      @news.attributes = params[:news]
      #@news.prepare_sitems(params[:sitems])

      if @news.save
        # add contenttype tag
        @news.save_tags([params[:type_id]])

        # add news_id to session
        add_to_session(:news_id,@news.id)

        # add relations to images
        picture_cat = Relation.find_or_create_by_name('Picture')
        get_images_from_session.each do |@image|
          if session[:wizard][:gallery_images].nil? || (!session[:wizard][:gallery_images].nil? && session[:wizard][:gallery_images].select{|i| i == @image.id}.size == 0)
          ## no gallery or image is not in gallery
          @news.sobject.create_in_relations_as_from :to => @image.sobject, :relation => picture_cat
          end
        end

        # add relation to gallery
        unless session[:wizard][:gallery_id].nil?
          @gallery = Gallery.find(session[:wizard][:gallery_id])
          gallery_cat = Relation.find_or_create_by_name('Fotospecial')
          @news.sobject.create_in_relations_as_from :to => @gallery.sobject, :relation => gallery_cat
        end

        # unpublish
        @news.sitems.each{|s| s.status = 0; s.save }

        redirect_to :action => 'wizard4', :type_id => params[:type_id]
      end
    end
  end

  # TAGS
  def wizard4
    news_id = get_from_session(:news_id)
    @news = News.find(news_id)
    if request.post?
      @news.save_tags(params["tags"])
      # put tags on all images + gallery
      get_images_from_session.each do |@image|
        @image.save_tags(params["tags"])
      end
      gallery_id = get_from_session(:gallery_id)
      if Gallery.exists?(gallery_id)
        @gallery = Gallery.find(gallery_id)
        @gallery.save_tags(params["tags"])
      end

      redirect_to :action => 'wizard5', :type_id => params[:type_id]
    end
  end

  # RELATIONS
  def wizard5
    news_id = get_from_session(:news_id)
    @news = News.find(news_id)
    if request.post?
      @news.save_relations(params["relations"])
      redirect_to :action => 'wizard6', :type_id => params[:type_id]
    end
  end

  # WEBSITES
  def wizard6
    news_id = get_from_session(:news_id)
    @news = News.find(news_id)
    if request.post?
      @news.prepare_sitems(params[:sitems])
      @news.save
      gallery_id = get_from_session(:gallery_id)
      if Gallery.exists?(gallery_id)
        @gallery = Gallery.find(gallery_id)
        @gallery.prepare_sitems(params[:sitems])
        @gallery.save
      end
      reset_session
      redirect_to :action => 'list', :type_id => params[:type_id]
    end
  end

  protected

  def get_from_session(key)
    session[:wizard] = {} if session[:wizard].nil?
    session[:wizard][key]
  end

  def get_images_from_session
    return Image.find(:all, :conditions => ["images.created_on > ? AND created_by = ?", get_from_session(:images_time), AdminUser.current_user.id], :include => :sobject)
  end

  def add_to_session(key,value)
    session[:wizard] = {} if session[:wizard].nil?
    session[:wizard][key] = value
  end

  def reset_session
    session[:wizard] = {}
  end

end
