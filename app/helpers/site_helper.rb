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

  def link_for(content_item, options = {})
    # FIXME: this does not work reliably when there are multiple content_types with the same core_content_type
    return if content_item.nil?
    return if content_item..ctype.nil?
    link_hash = {:controller => "site", 
                 :action => "content",
                 :site => controller.site, 
                 :type=> content_item.ctype.core_content_type.downcase, 
                 :id => content_item.id }
    url_for link_hash.update(options)
  end

  def truncate_with_words(text, length = 30, truncate_string = "...")
    if text.nil? then return end

    nearest_left_space = length - truncate_string.chars.length
    nearest_left_space -= 1 until text.chars[nearest_left_space] == 32 or nearest_left_space == 0

    text.chars.length > length ? text.chars[0...nearest_left_space] + truncate_string : text
  end

  # selected_menu_id is the id of currently selected menu
  def find_menu(selected_menu_id)
    if selected_menu_id
      @menuselect = Menu.find(selected_menu_id.to_i)
      selectpath = @menuselect.self_and_ancestors
    else
      @menuselect = nil
      selectpath = []
    end
    parents = (selectpath.map{|m| m.parent}+[@menuselect]).uniq-[nil]
    parents_sql_filter = parents.empty? ? '' : " OR parent_id IN (#{parents.map{|p| p.id}.join(',')})"
  
    # retrieve only the menus that need to be open (and are published on current site)
    allmenus = Menu.find(:all, 
                         :conditions => "(parent_id IS NULL #{parents_sql_filter}) AND sitems.website_id=#{Website.find_by_name(site).id} AND sitems.is_published=1", 
                         :order => 'lft', :include => :sitems)

    # mark where to open and close html lists
    @menus = []
    allmenus.each_index do |i|
        @menus[i] = {:indent => allmenus[i].level, 
                     :title  => "#{allmenus[i].title}",
                     :children_count => allmenus[i].all_children_count,
                     :link  =>  allmenus[i].link.blank? ? "#" : allmenus[i].link,
                     :menu_id => allmenus[i].id}
        @menus[i][:selected] =  allmenus[i] == @menuselect
    end
    allmenus[1..-1].each_index do |i|
      # "open" means that we our menu item has children.
      # "close" means that our items is the last one in the list (scope: indent)
      @menus[i][:open] = @menus[i+1][:indent] > @menus[i][:indent]
      @menus[i][:close] = [0, @menus[i][:indent] - @menus[i+1][:indent]].max
    end
    @menus.first[:open] = true
    @menus.last[:open] = false
    @menus.first[:close] = 0
    @menus.last[:close] = 1
    
    return @menus
  end

 
  #
  def find_breadcrumb(item, options={})
    return if item.nil?
    raise 'Not a nested set model !' unless item.respond_to?(:acts_as_nested_set_options)

    @elements = []
    item.self_and_ancestors.each do |ancestor|
      @elements << {:title => ancestor.title,
                    :link => ancestor.link,
                    :menu_id => ancestor.id,
                    :close => 0}
    end
    @elements.last[:close] = 1
    return @elements

  end 

  ### DEPRECATED

    # Get menu as a tree hash (recursive method :/ )
    def get_menu_tree(site, menu_id, linkTo = nil)
      $stderr.puts('DEPRECATION WARNING: get_menu_tree is deprecated; please use find_menu')
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
        if !uitem.blank? && !item.link.match("(http|ftp|https|)://.*")
          item.link.split("/").each { |litem| selected = (uitem == litem ? true : false) }
        end
      end
      #make the hash
      myHash = {
        :title => item.title,
        :link => ( item.link.blank? ? "#" : item.link ),
        :selected => selected,
        :id => item.id,
        :children => get_menu_tree_childs(item, link)
      }
      return myHash
    end



end
