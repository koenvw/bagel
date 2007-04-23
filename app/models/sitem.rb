class Sitem < ActiveRecord::Base
  belongs_to :website
  belongs_to :sobject
  belongs_to :content, :polymorphic => true

  acts_as_tree

  #FIXME: this is a hack for checkbox compatibility
  def status
    read_attribute(:status) == "Published" ? "1" : "0"
  end
  def status=(status)
    (status == "1" or status == "Published") ?
      write_attribute(:status,"Published") :
      write_attribute(:status,"Hidden")

  end
end
