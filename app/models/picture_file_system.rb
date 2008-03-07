

class PictureFileSystem < MediaItem

  has_attachment :storage         => :file_system,
#                 :thumbnail_class => 'MediaItemThumbnail',
                 :path_prefix     => 'public/assets',
                 :thumbnails      => Setting.image_thumbnails,
                 :content_type    => :image, # not related to Bagel content types
                 :processor       => Setting.image_processor,
                 :size            => 0..10.megabyte, # FIXME: yes we allow 0, sometimes the size is 0 after succesfull upload?
                 :content_type   => ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/bmp'] 

  # FIXME: these validation come from vendor/plugins/attachment_fu/lib/technoweenie/attachment_fu.rb
  # FIXME: other Picture* classes should validate this way
  validates_presence_of :size, :content_type, :filename
  validate              :attachment_attributes_valid?
  def attachment_attributes_valid?
    [:size, :content_type].each do |attr_name|
      enum = attachment_options[attr_name]
      errors.add attr_name, "#{send(attr_name)} not in #{enum.inspect}" unless enum.nil? || enum.include?(send(attr_name))
    end
  end

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
