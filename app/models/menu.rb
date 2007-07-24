class Menu < ActiveRecord::Base
  acts_as_enhanced_nested_set
  acts_as_content_type

  validates_presence_of :name

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = name.downcase.gsub(/ /,'_').gsub(/[^a-z_]/,'') unless name.nil?
    end
  end

  #FIXME: UGLY!!
  def link(site)
    if AppConfig[:websites].nil? || AppConfig[:websites][site] == nil
      website_id = Website.find_by_name(site)
    else
      website_id = AppConfig[:websites][site]
    end
    sitems.each do |sitem|
      return eval('"' + sitem.link + '"') if sitem.website_id = website_id && !sitem.link.nil?
    end
    return ""
  end

  # just to make ourselves consistent with the other ContentTypes
  def title
    name
  end

  def self.list(param)
    $stderr.puts('DEPRECATION WARNING: Menu.list is deprecated; please use Menu.find')
    find(:all)
  end

  def self.list(site,parent_id)
    find(
      :all,
      :order => "lft",
      :conditions=>"
        menus.parent_id='#{parent_id}'
        AND sitems.website_id=#{Website.find_by_name(site).id}
        AND sitems.status='Published'
      ",
      :include=>[:sitems]
    )
  end

end
