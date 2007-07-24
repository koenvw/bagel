class Generator < ActiveRecord::Base
  acts_as_content_type

  belongs_to :website
  belongs_to :generator_folder
  belongs_to :content_type

  validates_presence_of  :name
  # TODO readd validations
# validates_presence_of  :templating_engine
# validates_inclusion_of :templating_engine, :in => [ 'erb', 'liquid' ]

  def create_default_sitems
    # do nothing ..HA
  end

  def before_save
    prepare_sobject
  end

  # FIXME: wot does this do ?
  def template
    attributes["template"]
  end

  # just to make ourselves consistent with the other ContentTypes
  def title
    name
  end

  def dependencies
    (template.scan(/controller.include_template\("(\w+)"\)/) + 
     template.scan(/controller.render_generator\("(\w+)"\)/) + 
     template.scan(/controller.render_generator\('(\w+)'\)/)).flatten
  end

end
