class Website < ActiveRecord::Base

  validates_presence_of   :name
  validates_uniqueness_of :name

  has_many                :sitems,            :dependent => :destroy
  has_many                :generators,        :dependent => :destroy
  has_many                :generator_folders, :dependent => :destroy
  has_many                :url_mappings,      :dependent => :destroy

  # Liquid support

  def to_liquid
    WebsiteDrop.new(self)
  end

end
