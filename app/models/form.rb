class Form < ActiveRecord::Base
  acts_as_content_type
  belongs_to :form_definition

  validates_presence_of :name
  validates_presence_of :form_definition

  attr_accessor :data

  def initialize
    super
    initialize_data
  end

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = name unless name.nil?
    end
  end

  def initialize_data
    if @data.nil?
      unless read_attribute(:data).blank?
        @data = YAML.load(read_attribute(:data))
      else
        @data = {}
      end
    end
    @data
  end

  def check_data
    @data.each_key do |key|
      raise Exception.new("illegal key: #{key}") if key.to_s != "name" && key.to_s != "type_id" && self.orig_respond_to?(key)
    end
  end

  def data
    #FIXME: why do we still need to initialize ? -> initialize is not executed after Form.find()
    initialize_data if @data.nil?
    @data
  end

  def convert_data
    #FIXME: convert HashWithIndifferentAcces to a normal hash
    # be careful about the class for the keys (string or symbol?)
    # -> change method_missing accordingly (expects symbols now, keys are stored as string though)
    #
  end

  def before_save
    check_data
    write_attribute(:data, @data)
    # FIXME: acts_as_content_type also does a before_safe
    prepare_sitem # just to make ourselves consistent
    prepare_sobject
  end

  def method_missing(method_id, *arguments)
    # FIXME: why do we still need to initialize ? -> initialize is not executed after Form.find()
    initialize_data
    # FIXME: scanning the formdefinition template to check if a field exists is not safe
    if method_id.to_s.ends_with?("=")
      # an assignment, check if the field exists in the form definition
      field_name = method_id.to_s.chop.to_sym # remove "="
      super if field_name == :name
      if !attributes["form_definition_id"].nil? and form_definition.template.scan(/:#{field_name.to_s}/).size >0
        @data[field_name] = arguments.first
        check_data
      else
        # call mama and let her handle this
        super
      end
    elsif @data.has_key?(method_id)
      super if method_id == :name
      # the requested method_id exists in our data field -> return the value of it
      @data[method_id]
    elsif !attributes["form_definition_id"].nil? and form_definition.template.scan(/:#{method_id.to_s}/).size >0
        # in case new fields were added to the formdef -> just return nil
        nil
    else
      # call mama and let her handle this
      super
    end
  end

  # we must also check the internal data
  alias_method :orig_respond_to?, :respond_to?
  def respond_to?(method_id,include_private=false)
    orig_respond_to?(method_id,include_private) || (initialize_data && @data.has_key?(method_id))
  end

  # just to make ourselves consistent with the other ContentTypes
  def title
    name
  end

  def self.find_with_parameters(options = {})
    options.assert_valid_keys [:type,:conditions,:tag_names,:search_string,:limit,:offset,:order]
    cstr = ""; conditions = []
    # type
    if options[:type]
      if options[:type].is_a?(Hash)
        type_check = "AND (form_definition_id IN(?))"
        conditions << options[:type].map do |name| FormDefinition.find_by_name(name).id end.join(",")
      else
        type_check = "AND (form_definition_id=?)"
        conditions << FormDefinition.find_by_name(options[:type]).id.to_s
      end
    end
    # conditions
    if options[:conditions]
      condition_check = ""
      options[:conditions].each do |name,value|
        condition_check << "AND (data RLIKE ? )"
        conditions << "\n#{name}: [\"]?#{value}[\"]?"
      end
    end
    # tags
    if options[:tag_names]
      tag_check = "AND (1=0"
      options[:tag_names].each do |tag|
        tag_check << " OR cached_category_ids LIKE '%;#{Tag.find_by_name(tag).id};%' "
      end
      tag_check << ")"
    end
    # search_string
    if options[:search_string] and options[:search_string].size > 0
      search_check = "AND (data LIKE '%: %#{options[:search_string]}\\\\n%')"
    end

    # first element is the conditions string, then the parameters
    conditions.insert(0,"1=1 #{type_check} #{condition_check} #{tag_check}  #{search_check}" )

    find(
      :all,
      :conditions=>conditions,
      :limit   => options[:limit]  || nil,
      :offset  => options[:offset] || nil,
      :order   => options[:order]
    )
  end

end
