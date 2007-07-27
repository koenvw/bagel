class PictureFTP < MediaItem

  has_attachment :storage         => :ftp,
#                 :thumbnail_class => 'MediaItemThumbnail',
                 :thumbnails      => Setting.image_thumbnails,
                 :content_type    => :image, # not related to Bagel content types
                 :processor       => Setting.image_processor, 
				 :max_size => 10.megabytes

  validates_as_attachment

  acts_as_content_type
  acts_as_picture

  after_resize do |obj, image|
    obj.crop_and_add_watermark(image)
  end

  def set_title
    if self.title.blank?
      self.title = 'Untitled picture'
    end
  end

  def public_filename(thumbnail=nil)
    full_filename(thumbnail)
  end

end
