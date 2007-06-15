class Event < ActiveRecord::Base
  acts_as_content_type

  validates_presence_of :title

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end

  #FIXME: change the database table
  def updated_on
    updated_at
  end

  #FIXME: change the database table
  def created_on
    created_at
  end
end
