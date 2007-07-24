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

  def current_domain
    controller.current_domain
  end
  def current_url
    controller.current_url
  end

  def is_front?

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
  
  # Get menu as a tree hash (recursive method :/ )
  def get_menu_tree(site, menu_id, linkTo = nil)
    linkStr = ( linkTo.nil? ? site : linkTo )
    menu_items = find_menu(site, menu_id)
    tempArray = []
    menu_items.each do |mitem|
      if mitem.parent_id == menu_id
        tempArray << get_menu_tree_hash(mitem, linkStr)
      end
    end
    return tempArray
  end
  
  # -- get menu children
  private
  def get_menu_tree_childs(parent, link)
    if parent.has_children?
      tempArray = []
      parent.children.each do |child|
        tempArray << get_menu_tree_hash(child, link)
      end
      return tempArray
    end
    return false
  end

  # -- hash structure
  def get_menu_tree_hash(item, link)  
    # if item is selected (based on uri parsing)? 
    selected = false
    request.request_uri.split("/").each do |uitem| 
      if !uitem.blank? && !item.link(link).match("(http|ftp|https|)://.*")
        item.link(link).split("/").each do |litem|
          if uitem == litem
            selected = true
          end
        end
      end
    end
    #make the hash
    myHash = {
      :title => item.title,
      :link => ( item.link(link).blank? ? "#" : item.link(link) ),
      :selected => selected,
      :id => item.id,
      :children => get_menu_tree_childs(item, link)
    }
    return myHash
  end
  
end
