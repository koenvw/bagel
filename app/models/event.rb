class Event < ActiveRecord::Base
  acts_as_content_type

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end
end
