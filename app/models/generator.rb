class Generator < ActiveRecord::Base

  acts_as_content_type

  belongs_to :website
  belongs_to :generator_folder
  belongs_to :content_type

  validates_presence_of  :name
  validates_presence_of  :templating_engine
  validates_inclusion_of :templating_engine, :in => [ 'erb', 'liquid' ]

  def create_default_sitems
    # do nothing ..HA
  end

  def before_save
    prepare_sobject
  end

  # Accessors

  def template
    attributes["template"]
  end

  def title
    # Just to make ourselves consistent with the other ContentTypes
    name
  end

  # Miscellaneous

  def dependencies
    (template.scan(/controller.include_template\("(\w+)"\)/) + 
     template.scan(/controller.render_generator\("(\w+)"\)/) + 
     template.scan(/controller.render_generator\('(\w+)'\)/) + 
     template.scan(/include_template '(\w+)'/)).flatten
  end

  def assigns_as_hash(one={}, two={})
    @super = AutoCallingHash.new(one || {}, two || {})
    self.assigns.blank? ? {} : eval(self.assigns)
  rescue => exception
    new_exception = exception.class.new(exception.message + " (Generator: #{self.name})")
    new_exception.set_backtrace(exception.backtrace)
    raise new_exception
  end

end
