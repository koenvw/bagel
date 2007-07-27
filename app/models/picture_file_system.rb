class PictureFileSystem < MediaItem

  has_attachment :storage         => :file_system,
#                 :thumbnail_class => 'MediaItemThumbnail',
                 :path_prefix     => 'public/assets',
                 :thumbnails      => Setting.image_thumbnails,
                 :content_type    => :image, # not related to Bagel content types
                 :processor       => Setting.image_processor,
                 :max_size => 10.megabyte
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
