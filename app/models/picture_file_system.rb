class PictureFileSystem < MediaItem

  has_attachment :storage         => :file_system,
#                 :thumbnail_class => 'MediaItemThumbnail',
                 :path_prefix     => 'public/assets',
                 :thumbnails      => Setting.image_thumbnails,
                 :content_type    => :image, # not related to Bagel content types
                 :processor       => Setting.image_processor
  validates_as_attachment

  acts_as_content_type
  acts_as_picture

  after_resize do |obj, image|
    obj.crop_and_add_watermark(image)
  end

  def set_title
    if self.title.blank?
      self.title = '(Picture) ' + self.public_filename
    end
  end

end

##### AUTO55-SPECIFIC STUFF #####

# def after_save
#   super
#   exec_file_mapping
# end
# 
# def exec_file_mapping
#   settings = Setting.get("file_mapping")
#   return if settings.nil?
#   add_name = settings[:to_add_to_filename]
#   to_version= settings[:to_version] + "/"
#   from_version = settings[:from_version] + "/"
# 
#   return if add_name.nil? or to_version.nil?
# 
#   src_file = self.image
#   exte = File.extname(src_file)
#   file = File.basename(src_file, exte)
#   path = src_file[0..-((file+exte).size+1)]
#   dst_file = path + to_version + file +  add_name + exte
#   src_file = path + from_version + image_file
# 
#   FileUtils.ln src_file, dst_file unless File.exists?(dst_file)
# end
