class Gallery < ActiveRecord::Base #:nodoc:
  acts_as_content_type
  validates_presence_of :title

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end
end
