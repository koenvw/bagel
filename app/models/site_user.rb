class SiteUser < ActiveRecord::Base
  acts_as_content_type

  validates_presence_of :email
  validates_uniqueness_of :email
  validates_format_of :email, :with => AppConfig[:email_expression]


  # just to make ourselves consistent with the other ContentTypes
  def title
    email
  end

  def self.find_with_website_id(website_id)
    # FIXME: deprecated?
    find(:all, :conditions => ["website_id = ? AND is_published = 1 AND active = 1", website_id], :include => :sitems)
  end

end
