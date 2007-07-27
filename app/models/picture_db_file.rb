class PictureDbFile < MediaItem

  has_attachment :storage         => :db_file,
#                 :thumbnail_class => 'MediaItemThumbnail',
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
      self.title = 'Untitled picture'
    end
  end

  def full_filename(thumbnail=nil)
    'file://' + public_filename(thumbnail)
  end

  def public_filename(thumbnail=nil)
    thumbnail_options   = (thumbnail.nil? ? '' : '&thumbnail=' + thumbnail.to_s)
    disposition_options = '&disposition=inline'
    '/media_item_from_db?id=' + id.to_s + thumbnail_options + disposition_options
  end

end
