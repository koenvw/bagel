# MediaItem is the base class for all Media classes (Document, Picture*, Video, Audio)
class MediaItem < ActiveRecord::Base

  ALLOWED_CLASS_NAMES = %w{ PictureFileSystem PictureDbFile PictureS3 PictureFTP }
  PICTURE_CLASS_NAMES = %w{ PictureFileSystem PictureDbFile PictureS3 PictureFTP }

  # the content of the content field depends on the subclass 
  # eg. EXIF info for images, text-extraction for documents
  acts_as_ferret :fields           => [ :title, :description, :content ],
                 :remote           => AppConfig[:use_ferret_server],
                 :store_class_name => true if AppConfig[:use_ferret]

  acts_as_content_type

  # Returns the size of the file in bytes
  def file_size
    File.exist?(self.full_filename) ? File.size(self.full_filename) : 0
  end

  # Returns the MIME type for the image
  def mime_type
    MIME::Types.type_for(self.public_filename)
  end

  # Liquid support

  def to_liquid
    MediaItemDrop.new(self)
  end

end
