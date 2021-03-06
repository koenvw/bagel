# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def select_relation(type)
    select :relation1, :category2_id, Relation.find(:all,:order => "name").collect{ |p| [p.name,p.id] }, { :include_blank => true }
  end

  def tree_select(object, method, choices, options = {}, html_options = {})
    select object, method, choices.collect {|p| [indent(p, "..." ).to_s + p.name.to_s,p.id]}, { :include_blank => true }, html_options
  end

  # <%= select_nested_set_tag :parent_id, Menu, @menu.parent_id %>
  def select_nested_set_tag(name, type, selected = 0, html_options = {})
    options = options_for_select(nested_set_options_for_select(type) { |item| "#{'...' * item.level}#{item.name}" }.unshift([type.to_s,""]), selected)
    select_tag name, options, html_options
  end

  def select_nested_set(object, method, type, options = {}, html_options = {})
    select object, method, nested_set_options_for_select(type) { |item| ["#{'...' * item.level}#{item.name}", item.id] }, { :include_blank => true }, html_options
  end

  def figure_out_content_type_name(item)
    (item.ctype && item.ctype.name.downcase) || (params[:type_id] && ContentType.find(params[:type_id]).name.downcase)
  end
  def figure_out_action(item)
    item.new_record? ? "Creating" : "Editing"
  end

  def indent(item, indent_str)
    indent_str * item.level
  end

  def bagel_pagination_links(paginator)
    params.delete(:controller) # links to /admin/admin otherwise ?
    params.delete(:page) #
    out = ''
    out << link_to("previous", {:page => paginator.current.previous}.merge(params)) if paginator.current.previous
    out << pagination_links_each(paginator, :link_to_current_page => true) do |num|
      params[:page] == num.to_s ? cssclass = "selected" : cssclass = "notselected"
      link_to num, {:page => num}.merge(params), {:class => cssclass }
    end
    out << link_to("next", {:page => paginator.current.next}.merge(params)) if paginator.current.next
    out
  end

  def generate_id
    chars = ["A".."Z","a".."z","0".."9"].collect { |r| r.to_a }.join
    password = (1..8).collect { chars[rand(chars.size)] }.pack("C*")
  end

   # TODO: redundant ??
  def link_to_arrow(item, direction)
    img = nil

    case direction
      when :move_left
        img = 'arrow_left_blue.png' unless item.first?
      when :move_right
        img = 'arrow_right_blue.png' unless item.last?
    end

    if img.nil?
      image_tag 'dot_clear.gif', :width => 16, :height => 16
    else
      link_to(image_tag(img, :border => 0) , :action => direction.to_s, :id => item)
    end
  end

  def url_for_if_authorized(options={}, *parameters_for_method_reference)
    # Get controller path and action
    url  = url_for(options, *parameters_for_method_reference)
    path = URI.parse(url).path
    hash = ActionController::Routing::Routes.recognize_path(path)
    controller_name, action = hash[:controller], hash[:action].to_sym

    # Get controller
    controller_name = File.split(controller_name).collect{ |s| s.camelize }.join('::') + 'Controller'
    return nil unless controller_name =~ /^Admin::/
    controller = eval(controller_name)

    # Check permissions
    required_permissions = controller.permission_scheme[action] || []
    is_authorized = (required_permissions.select { |p| AdminUser.current_user.has_admin_permission?(p) }.size > 0)

    is_authorized ? url : nil
  end

  def link_to_if_authorized(name, options={}, html_options=nil, *parameters_for_method_reference)
    url = url_for_if_authorized(options, *parameters_for_method_reference)
    url.nil? ? '' : link_to(name, options, html_options, *parameters_for_method_reference)
  end

  def menu_item_is_active?(menu_item, request_env)
    # Check element itself
    return true if menu_item['url'] == request.env['REQUEST_URI']

    # Check child elements
    return (((menu_item['children'] || []) + (menu_item['hidden_children'] || [])).select { |i| request.env['REQUEST_URI'].starts_with?(i['url']) }.length != 0)
  end

  def menu_item_children(menu_item)
    ((menu_item.nil? ? [] : menu_item['children']) || [])
  end

  def figure_out_edit_link(ctype)
    action = "edit"
    param_id = nil
    form_definition_id = nil
    type = ctype.core_content_type
    ctrl = type.tableize.downcase
    if type == "Form"
      form_definition_id = ctype.extra_info
    end
    if AppConfig[:assistant_controllers] and AppConfig[:assistant_controllers].include?(ctype.name)
      link_hash = { :controller => AppConfig[:assistant_controllers][ctype.name], :type_id => ctype.id }
    elsif AppConfig[:wizard_for] && AppConfig[:wizard_for].include?(ctype.name)
      link_hash = {:controller => "content", :action => "wizard_#{ctype.name.rubify}", :id => param_id, :type_id => ctype.id, :form_definition_id => form_definition_id }
    else
      type_hash = ( MediaItem::ALLOWED_CLASS_NAMES.include?(ctype.extra_info) ? { :type => ctype.extra_info } : {} )
      link_hash = { :controller => ctrl, :action => action, :id => param_id, :type_id => ctype.id, :form_definition_id => form_definition_id }.merge(type_hash)
    end
  end
  
  def render_insite_editor 
    if AdminUser.current_user
      link_hash = "/admin/#{@content_type.pluralize}/edit/#{instance_variable_get("@"+@content_type).id}"
      user = AdminUser.find(instance_variable_get("@"+@content_type).sobject.updated_by)
      moreinfolink = link_to("more info","#",:onclick=>"toggle('insite_moreinfocontainer')") 
      tags = instance_variable_get("@"+@content_type).sobject.content.tags.map{|tag| ', '+tag.name }.to_s.sub(',','')
      relations = instance_variable_get("@"+@content_type).sobject.content.relations.map{|rel| ', '+rel.title }.to_s.sub(',','')
      websites = instance_variable_get("@"+@content_type).sobject.content.sitems.map{|sitem| ', '+sitem.name }.to_s.sub(',','')
      
      result = <<-HTML
        #{stylesheet_link_tag("/plugin_assets/bagel/stylesheets/insite-infobar.css")}
        <div id="insite_infobar" >
          <div class="bg">
            <div class="metainfo">
              <strong>title: </strong>#{instance_variable_get("@"+@content_type).sobject.name}<br/>
              <strong>last update: </strong>#{instance_variable_get("@"+@content_type).sobject.updated_on.formatted} by #{user.firstname} #{user.lastname}<br/>
            </div>
            <div class="infobar_button"><div class="left"></div><div class="middle">#{link_to_if_authorized("edit", link_hash)}</div><div class="right"></div></div>
  	  HTML
    	if request.env['REQUEST_URI'].match(/\?/)
    	      result += "<div class=\"infobar_button\"><div class=\"left\"></div><div class=\"middle\">"+link_to("clear cache", "#{request.env['REQUEST_URI']}&clear=1")+"</div><div class=\"right\"></div></div>"
    	else
    	      result += "<div class=\"infobar_button\"><div class=\"left\"></div><div class=\"middle\">"+link_to("clear cache", "#{request.env['REQUEST_URI']}?clear=1") +"</div><div class=\"right\"></div></div>"
    	end
    	result += <<-HTML
    	      <div class="infobar_button"><div class="left"></div><div class="middle">#{moreinfolink}</div><div class="right"></div>
    	    </div>
    	  </div>
    	  <div id="insite_moreinfocontainer" style="display:none">
    	    <div class="metainfo">
    	      <strong>tags: </strong>#{tags} |
    	      <strong>relations: </strong>#{relations} |
    	      <strong>websites: </strong>#{websites}
    	    </div>
    	  </div>
    	HTML
    	
    end
  end

public

  ########## DEPRECATED ##########

  def fckeditor_text_field(object, method, options = {})
    $stderr.puts 'DEPRECATION WARNING: ApplicationHelper#fckeditor_text_field() is deprecated; use tinymce instead'
    text_area(object, method, options ) +
    javascript_tag( "var oFCKeditor = new FCKeditor('" + object + "[" + method + "]');oFCKeditor.ReplaceTextarea()" )
  end

  def select_category(type)
    #FIXME: remove
    $stderr.puts 'DEPRECATION WARNING: categories are split in indivual objects, use those'
    raise NotImplementedError.new("categories are split in indivual objects, use those")
  end

  def breadcrumb(category_id)
    $stderr.puts 'DEPRECATION WARNING: ApplicationHelper#breadcrumb() is deprecated; use nested_set_full_outline() instead'
    c = Category.find(category_id)
    content = link_to("Home", :action => "list", :id => '')
    begin
      content << link_to(c.name, :id => c.id)
      c = c.parent
    end until c.nil?
    content_tag("div", content, "id" => "breadcrumb")
  end

  def current_user
    $stderr.puts 'DEPRECATION WARNING: ApplicationHelper#current_user() is deprecated; use AdminUser#current_user() instead.'
    AdminUser.current_user
  end

  def escape_specials(str,reverse=false)
   $stderr.puts 'DEPRECATION WARNING: escape_specials is deprecated, use the html_entities lib'
    c=Array[
        "&#198;","�","&#193;","�","&#194;","�","&#192;","�","&#197;","�","&#195;","�","&#196;","�","&#199;","�",
        "&#208;","�","&#201;","�","&#202;","�","&#200;","�","&#203;","�","&#205;","�","&#206;","�","&#204;","�",
        "&#207;","�","&#209;","�","&#211;","�","&#212;","�","&#210;","�","&#216;","�","&#213;","�","&#214;","�",
        "&#222;","�","&#218;","�","&#219;","�","&#217;","�","&#220;","�","&#221;","�","&#225;","�","&#226;","�",
        "&#230;","�","&#224;","�","&#229;","�","&#227;","�","&#228;","�","&#231;","�","&#233;","�","&#234;","�",
        "&#232;","�","&#240;","�","&#235;","�","&#237;","�","&#238;","�","&#236;","�","&#239;","�","&#241;","�",
        "&#243;","�","&#244;","�","&#242;","�","&#248;","�","&#245;","�","&#246;","�","&#223;","�","&#254;","�",
        "&#250;","�","&#251;","�","&#249;","�","&#252;","�","&#253;","�","&#255;","�","&lt;"  ,"<","&gt;"  ,">",
        "&quot;","\"","&reg;","�","&copy;","�","&sup2;","�","&sup3;","�"
        ]

    r=Array.new
    for char in c
      r<<char
      unless r[1]==nil
        if reverse
          str=str.gsub(r[0],r[1])
        else
          str=str.gsub(r[1],r[0])
        end
        r.clear
      end
    end
    return str
  end

end
