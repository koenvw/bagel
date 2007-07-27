class Admin::WebfolderController < ApplicationController

  def import_do

    # Make sure something is selected
    if params[:entries].nil?
      flash[:warning] = 'You didn\'t select any files or folders to import!'
      redirect_to :controller => 'home', :action => 'webfolder'
      return
    end

    # Find content type
    content_type = ContentType.find(params[:file_content_type])

    # Loop through all files and folders on the root
    params[:entries].each do |entry|
      if File.directory?(entry)
        import_folder_do(entry, content_type, params[:folder_relation])
      else
        import_file_do(entry, content_type)
      end
    end

    # Done
    redirect_to :controller => 'content', :action => 'list', :tag_id => params[:tag_id]
  end

private

  def import_folder_do(entry, content_type, relation_id)
    # Find relation
    relation = Relation.find(relation_id)

    # Make sure content type and relation are compatible
    unless relation.content_types.include?(content_type)
      flash[:error] = 'The selected relation does not allow media items of the selected content type.'
      redirect_to :controller => 'home', :action => 'webfolder'
      return
    end

    # Make sure we're safe
    unless MediaItem::ALLOWED_CLASS_NAMES.include?(content_type.extra_info)
      flash[:error] = 'The extra info of the content type you selected is not valid.'
      redirect_to :controller => 'home', :action => 'webfolder'
      return
    end

    # Create container
    container = Container.new
    container.title   = File.basename(entry)
    container.type_id = relation.content_type.id
    container.save

    # Add tags to container
    container.save_tags(params[:tags])

    Dir.entries(entry).reject { |sub_entry| sub_entry.starts_with?('.') or sub_entry == '_imported' }.each do |sub_entry|
      # Convert sub_entry into a path
      sub_entry = File.join(entry, sub_entry)

      # Create a media item of the requested type
      case content_type.extra_info
      when 'PictureS3'
        media_item = PictureS3.new
      when 'PictureFTP'
        media_item = PictureFTP.new
      when 'PictureFileSystem'
        media_item = PictureFileSystem.new
      when 'PictureDbFile'
        media_item = PictureDbFile.new
      end
      media_item[:type]  = content_type.extra_info
      media_item.type_id = content_type.id

      full_path = Pathname.new(sub_entry).realpath.to_s

      # Update media item with file data
      File.open(full_path) do |file|
        file.extend FileCompat

        media_item.title         = File.basename(full_path)
        media_item.description   = ''
        media_item.uploaded_data = file
        media_item.content_type  = MIME::Types.type_for(full_path).to_s
        media_item.save
      end

      # Add tags
      media_item.save_tags(params[:tags])

      # Add relationships
      container.add_relation_unless(media_item.sobject.id, relation.id)
    end

    # Create '_imported' directory if necessary
    imported_dirname     = File.join(File.dirname(entry), '_imported')
    folder_imported_name = File.join(imported_dirname, File.basename(entry))
    FileUtils.rm_r(imported_dirname) if File.exist?(imported_dirname)
    FileUtils.mkdir(imported_dirname) unless File.exists?(imported_dirname)

    # Move directory out of the way
    FileUtils.mv(entry, folder_imported_name)

    # Done
    flash[:notice] = 'The select folders and its files have been successfully imported.'
  end

  def import_file_do(entry, content_type)
    # Make sure we're safe
    unless MediaItem::ALLOWED_CLASS_NAMES.include?(content_type.extra_info)
      flash[:error] = 'The extra info of the content type you selected is not valid.'
      redirect_to :controller => 'home', :action => 'webfolder'
      return
    end

    # Create a media item of the requested type
    case content_type.extra_info
    when 'PictureS3'
      media_item = PictureS3.new
    when 'PictureFTP'
      media_item = PictureFTP.new
    when 'PictureFileSystem'
      media_item = PictureFileSystem.new
    when 'PictureDbFile'
      media_item = PictureDbFile.new
    end
    media_item[:type]  = content_type.extra_info
    media_item.type_id = content_type_id

    full_path = Pathname.new(entry).realpath.to_s

    # Update media item with file data
    File.open(full_path) do |file|
      file.extend FileCompat

      media_item.title         = File.basename(full_path)
      media_item.description   = ''
      media_item.uploaded_data = file
      media_item.content_type  = MIME::Types.type_for(full_path).to_s
      media_item.save
    end

    # Add tags
    media_item.save_tags(params[:tags])

    # Move files out of the way
    imported_dirname = File.dirname(full_path) + '/_imported'
    FileUtils.mkdir(imported_dirname) unless File.exists?(imported_dirname)
    FileUtils.mv(full_path, File.join(imported_dirname, File.basename(full_path)))

    # Done
    flash[:notice] = 'The selected media items were successfully imported.'
  end

end
