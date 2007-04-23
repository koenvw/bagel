class Setting < ActiveRecord::Base

  acts_as_enhanced_nested_set

  validates_presence_of   :name
  validates_uniqueness_of :name, :scope => :parent_id

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
        if child.value_type == "symbol"
          type = "sym"
        else
          type = child.value_type.first
        end

        hash[child.name.to_sym] = child.value.respond_to?("to_#{type}") ?
                                  child.value.send("to_#{type}") :
                                  child.value.to_s
      end
    end

    hash
  end

end
