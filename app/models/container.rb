class Container < ActiveRecord::Base
  acts_as_content_type
  validates_presence_of :title

  # FIXME: rename column
  def body
    description
  end
  def body=(text)
    description = text
  end

  # Liquid support

  def to_liquid
    ContainerDrop.new(self)
  end

end
