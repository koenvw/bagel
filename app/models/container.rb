class Container < ActiveRecord::Base
  acts_as_content_type
  validates_presence_of :title

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end

  # FIXME: rename column
  def body
    description
  end
  def body=(text)
    description = text
  end

end
