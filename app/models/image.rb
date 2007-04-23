class Image < ActiveRecord::Base
  acts_as_content_type

  file_column :image,
        :store_dir => :get_storage_dir,
        :magick    => Setting.get_cached("ImageSettings")

  validates_file_format_of :image, :in => ["jpg","jpeg","gif","png"]
  validates_presence_of :image

  #FIXME: needed sobject_id when retrieving image record for: options_from_collection_for_select
  def sobject_id
    sobject.id
  end

  def after_initialize
    # Hack for getting url_for_file_column to work ?!
    image_options[:base_url] = get_storage_dir
    super
  end

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end

  def get_storage_dir
    if new_record?
      "assets/" + Date.today.year.to_s + Date.today.month.to_s.rjust(2,"0")
    else
      "assets/" + created_on.year.to_s + created_on.month.to_s.rjust(2,"0")
    end
  end

  def image_filename
    l = image.length
    image[image.rindex('/public')+'/public'.length ,image.length-image.rindex('/public')]
  end

  def image_file
    attributes['image']
  end

  def add_water (dst)
    file_name = Setting.get("ImageSettings")[:watermark_image]
    if File.exists?(file_name)
      src = Magick::Image.read(file_name).first
      return dst.composite(src, Magick::NorthEastGravity, Magick::OverCompositeOp)
    else
      return dst
    end
  end

  def add_water_url (dst)
    file_name = Setting.get("ImageSettings")[:watermark_image_url]
    if File.exists?(file_name)
      src = Magick::Image.read(file_name).first
      return dst.composite(src, Magick::SouthEastGravity, Magick::OverCompositeOp)
    else
      return dst
    end
  end

  def add_water_vibes_url (dst)
    file_name = Setting.get("ImageSettings")[:watermark_image_autovibes_url]
    if File.exists?(file_name)
      src = Magick::Image.read(file_name).first
      return dst.composite(src, Magick::SouthEastGravity, Magick::OverCompositeOp)
    else
      return dst
    end
  end

  def add_water_vibes (dst)
    file_name = Setting.get("ImageSettings")[:watermark_image_autovibes]
    if File.exists?(file_name)
      src = Magick::Image.read(file_name).first
      return dst.composite(src, Magick::SouthEastGravity, Magick::OverCompositeOp)
    else
      return dst
    end
  end

  def after_save
    exec_file_mapping
    super
  end

  def exec_file_mapping
    settings = Setting.get("file_mapping")
    return if settings.nil?
    add_name = settings[:to_add_to_filename]
    to_version= settings[:to_version] + "/"
    from_version = settings[:from_version] + "/"

    return if add_name.nil? or to_version.nil?

    src_file = self.image
    exte = File.extname(src_file)
    file = File.basename(src_file, exte)
    path = src_file[0..-((file+exte).size+1)]
    dst_file = path + to_version + file +  add_name + exte
    src_file = path + from_version + image_file

    FileUtils.ln src_file, dst_file unless File.exists?(dst_file)
  end

  def self.find_all_by_tag(tag_name)
    Sobject.find(:all, :include => :categories, :conditions => ["categories.name=?",tag_name]).map { |sobject| sobject.content }
  end

end
