module SiteHelper

  def find(params = {})
    Sobject.find_with_parameters(params)
  end

  def content_type
    controller.content_type
  end

  def content_title
    controller.content_title
  end

  def site
    controller.site
  end

  def site_id
    controller.site_id
  end

  def domain
    controller.domain
  end

  def find_menu(site,menu_id)
    root = Menu.find(menu_id)
    items_not_published = Menu.find(:all,:conditions=>"
        menus.parent_id='#{menu_id}'
        AND sitems.website_id=#{Website.find_by_name(site).id}
        AND sitems.status='Hidden'
      ",
      :include=>[:sitems]
    )
    root.all_children(:exclude => items_not_published)
  end

end
