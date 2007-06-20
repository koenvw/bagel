class Generator < ActiveRecord::Base
  acts_as_content_type

  belongs_to :website
  belongs_to :generator_folder
  validates_presence_of :name

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
    template.scan(/controller.include_template\("(\w+)"\)/).flatten
  end

end
