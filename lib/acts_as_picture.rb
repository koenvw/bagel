module ActsAsPicture

  def self.append_features(base)
    super
    base.extend(ClassMethods)
  end

  module ClassMethods

    def acts_as_picture
      class_eval do
        include InstanceMethods
      end
    end

  end

  module InstanceMethods

    def version_settings
      Setting.get("ImageSettings")[:versions][self.thumbnail.to_sym]
    end

    def default_thumbnail_public_filename
      self.public_filename(Setting.get("ImageSettings")[:default].to_sym)
    end

    def crop_and_add_watermark(image)
      watermark_positions = {
        'top'          => Magick::NorthGravity,
        'top_right'    => Magick::NorthEastGravity,
        'right'        => Magick::EastGravity,
        'bottom_right' => Magick::SouthEastGravity,
        'bottom'       => Magick::SouthGravity,
        'bottom_left'  => Magick::SouthWestGravity,
        'left'         => Magick::WestGravity,
        'top_left'     => Magick::NorthWestGravity,
        'center'       => Magick::CenterGravity
      }

      # Skip original image
      return if self.thumbnail.blank?

      # Get version for this object
      version = self.version_settings

      # Convert ImageScience image to an RMagick image if necessary
      if attachment_options[:processor] == :image_science
        tempfile = Tempfile.new('image_science')
        tempfile.close
        image.save(tempfile.path)
        image = Magick::Image.read(tempfile.path).first
      end

      # Crop
      unless version[:crop].nil?
        crop_width, crop_height = *version[:crop].split(':').map { |i| i.to_i } 
        image.crop_resized!(crop_width, crop_height, Magick::CenterGravity)
      end

      # Add watermark
      unless version[:watermark_image].nil? or version[:watermark_position].nil?
        # Get watermark image
        return unless File.exist?(version[:watermark_image])
        watermark_image = Magick::Image.read(version[:watermark_image]).first

        # Composite
        gravity = watermark_positions[version[:watermark_position]]
        image.composite!(watermark_image, gravity, Magick::OverCompositeOp)
      end

      # Write edited image
      self.temp_path = self.write_to_temp_file(image.to_blob)
    end

    def update_thumbnails
      return unless parent_id.blank?
      temp_file = temp_path || create_temp_file
      attachment_options[:thumbnails].each { |suffix, size| create_or_update_thumbnail(temp_file, suffix, *size) }
    end

  end

end
