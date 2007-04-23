class Gallery < ActiveRecord::Base
  acts_as_content_type

  validates_presence_of :title

  def id_url
    "#{id}-#{title.downcase.gsub(/[^a-z1-9]+/i, '-')}"
  end

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end
end
