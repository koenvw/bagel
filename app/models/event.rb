class Event < ActiveRecord::Base
  acts_as_content_type

  validates_presence_of :title

  #FIXME: change the database table
  def updated_on
    updated_at
  end

  #FIXME: change the database table
  def created_on
    created_at
  end

  # Liquid support

  def to_liquid
    EventDrop.new(self)
  end

end
