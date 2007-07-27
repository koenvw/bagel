class Menu < ActiveRecord::Base
  acts_as_enhanced_nested_set
  acts_as_content_type

  validates_presence_of :name

  # Compatibility

  def link(site=nil)
    if site.nil?
      attributes['link']
    else
      link_to_site(site) unless site.nil?
    end
  end

  def title
    # Just to make ourselves consistent with the other ContentTypes
    name
  end

  # Liquid support

  def to_liquid
    MenuDrop.new(self)
  end

  # Deprecated

  def link_to_site(site)
    $stderr.puts('DEPRECATION WARNING: Menu#link with a parameter is deprecated; please use Menu#link without parameters')
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

  def self.list(param)
    $stderr.puts('DEPRECATION WARNING: Menu.list is deprecated; please use Menu.find')
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
