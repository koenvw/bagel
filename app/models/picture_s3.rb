class PictureS3 < MediaItem

  has_attachment :storage         => :s3,
#                 :thumbnail_class => 'MediaItemThumbnail',
                 :thumbnails      => Setting.image_thumbnails,
                 :content_type    => :image, # not related to Bagel content types
                 :processor       => Setting.image_processor
                 :size            => 0..10.megabyte, # FIXME: yes we allow 0, sometimes the size is 0 after succesfull upload?
                 :content_type   => ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png','image/bmp'] 

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
