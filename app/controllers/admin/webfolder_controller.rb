class Admin::WebfolderController < ApplicationController

  def import_do
    # for each checked entry
    if params[:entries].nil?
      flash[:warning] = 'No selection made.'
      redirect_to :controller => "home", :action => 'webfolder' and return
    end
    params[:entries].each do |entry|
      if File.directory?(entry)
        # create a gallery
        Gallery.transaction do
          @gallery = Gallery.create :title => File.basename(entry)
          # add tags to gallery
          @gallery.save_tags(params[:tags])
          ## for each file in the folder
          Dir.entries(entry).each do |subentry|
            unless [".","..",".DAV"].include?(subentry)
              ### create an image
              File.open(entry + "/" + subentry) { |imgfile| @image = Image.create :image => imgfile, :title => subentry }
              ### and set the relation to the gallery
              # FIXME: hard coded relation
              picture_cat = Relation.find_or_create_by_name('Picture')
              @gallery.sobject.create_in_relations_as_from :to => @image.sobject, :category => picture_cat
              # add tags to image
              @image.save_tags(params[:tags])
            end
          end
          # all images imported -> move folder
          FileUtils.rm_r(File.dirname(entry) + "/_imported/" +File.basename(entry)) if File.exists?(File.dirname(entry) + "/_imported/" +File.basename(entry))
          FileUtils.mkdir(File.dirname(entry) + "/_imported") unless File.exists?(File.dirname(entry) + "/_imported")
          FileUtils.mv(entry, File.dirname(entry) + "/_imported")
          flash[:notice] = 'Galleries were successfully created.'
        end
      else
        # create an image
        Image.transaction do
          File.open(entry) { |imgfile| @image = Image.create :image => imgfile, :title => File.basename(entry) }
          # add tags to image
          @image.save_tags(params[:tags])
          # move file out of the way
          FileUtils.mv(entry, File.dirname(entry) + "/_imported")
        end
        flash[:notice] = 'Images were successfully created.'
      end
    end
    redirect_to :controller => "content", :action => 'list', :tag_id => params[:tag_id]
  end

end
