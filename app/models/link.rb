class Link < ActiveRecord::Base
  acts_as_content_type

  validates_presence_of :title
  validates_presence_of :url

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end

end
