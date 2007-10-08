class Setting < ActiveRecord::Base

  acts_as_enhanced_nested_set

  validates_presence_of   :name
  validates_uniqueness_of :name, :scope => :parent_id

  def <=>(other_category)
    self.name.downcase <=> other_category.name.downcase
  end

  def self.get_cached(name)
    if AppConfig[:perform_caching]
      # CACHE is defined in environments
      # Cache is defined in memcached_util.rb (memcached_client)
      data = Cache.get(name.rubify)
      if data.nil?
        data = get(name)
        Cache.put(name.rubify,data,120) # expiry is in seconds
      end
    else
      data = get(name)
    end
    data
  end

  def self.get(name_or_id, hash = {})
    root = Setting.find_by_name(name_or_id) if name_or_id.to_i == 0
    root = Setting.find(name_or_id) if name_or_id.to_i != 0
    return nil if root.nil?

    if root.children.empty?
      {}
    else
      # for each child our setting has...
      root.children.each do |child|
        if child.has_children?
          # recurse if our child has children
          self.get(child.id, hash[child.name.to_sym] = {})
        else
          # value otherwise
          case child.value_type
          when "string"
            method = "to_s"
          when "integer"
            method = "to_i"
          when "float"
          when "boolean"
            method = "to_bool"
          when "symbol"
            method = "to_sym"
          when "date"
            method = "to_time"
          when "array"
            method = "split"
            param = ","
          else
            method = "to_s"
          end
          param ||= nil

          if child.value.respond_to?(method)
            if param
              hash[child.name.to_sym] = child.value.send(method, param)
            else
              hash[child.name.to_sym] = child.value.send(method)
            end
          else
            hash[child.name.to_sym] = child.value.to_s
          end
        end
      end

      hash
    end
  end

  # Convenience methods - Image

  def self.image_thumbnails
    self.image_versions.inject({}) { |memo, (k,v)| memo[k] = v[:size] ; memo }
  end

  def self.image_processor
    (self.get("ImageSettings")[:processor] || :rmagick).to_sym
  end

  def self.image_versions
    (Setting.get('ImageSettings')[:versions] || {}).merge({
      :media_gallery => media_gallery_image_version,
      :relationship  => relationship_image_version
    })
  end

  def self.media_gallery_image_version
    { :crop => '150:94', :size => '100%' }
  end

  def self.relationship_image_version
    { :crop => '67:50', :size => '100%' }
  end

  # Convenience methods - Languages

  def self.languages
    # Returns something like [ { :name => "English", :code => "en" }, { :name => "Dutch", :code => "nl" } ]
    result = ((self.get_cached('LanguageSettings') || {})[:languages] || '')
    result = result.split(',').map { |l| l.split('=').map(&:strip) }
    result.map! { |l| { :code => l[0], :name => l[1] } }
    result.sort! { |x,y| x[:name] <=> y[:name] }
  end

  def self.language_name_for_code(code)
    matching_languages = self.languages.select { |l| l[:code].to_sym == code.to_sym } || []
    (matching_languages.first || {})[:name]
  end

  # Convenience methods - Translation

  def self.translation_enabled?
    (self.get("LanguageSettings") || {})[:translation_enabled] == true
  end

  # Convenience methods - Sharing

  def self.sharing_enabled?
    (self.get("SharingSettings") || {})[:enabled] == true
  end

  def self.delicious_credentials
    res = self.get("SharingSettings") || {}
    { :username => res[:delicious_username], :password => res[:delicious_password] }
  end

end
