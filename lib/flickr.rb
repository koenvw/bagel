require 'rubygems'
require 'flickraw'

def flickr_photos_for(username)
  person = flickr.people.findByUsername(:username => username)
  photos = flickr.people.getPublicPhotos(:user_id => person.nsid, :extras => 'original_format')

  photos.map do |photo|
    farm            = photo.farm
    server          = photo.server
    id              = photo.id
    secret          = photo.secret
    original_secret = photo.originalsecret
    original_format = photo.originalformat

    original_url    = "http://farm#{farm}.static.flickr.com/#{server}/#{id}_#{original_secret}_o.#{original_format}"
    thumbnail_url   = "http://farm#{farm}.static.flickr.com/#{server}/#{id}_#{secret}_s.jpg"

    {
      :title => photo.title,
      :original_url => original_url,
      :thumbnail_url => thumbnail_url
    }
  end
end
