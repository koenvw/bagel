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

    # for each child our setting has...
    Setting.find(root.id).children.each do |child|
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

        hash[child.name.to_sym] = if child.value.respond_to?(method)
          if param
            child.value.send(method,param)
          else
            child.value.send(method)
          end
        else
          child.value.to_s
        end
      end
    end

    hash
  end

end
