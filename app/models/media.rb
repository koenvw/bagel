# Media is the base class for all Media classes (Document, Image, Video, Audio)
class Media < ActiveRecord::Base
  # the content of the content field depends on the subclass 
  # eg. EXIF info for images, text-extraction for documents
  acts_as_ferret :fields => [ :title, :description, :content ],
                 :remote => AppConfig[:use_ferret_server],
                 :store_class_name => true

end
