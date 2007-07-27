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

protected

  def is_spam_comment?(author, text)
    # Check whether spam protection is enabled
    return false unless (Setting.get('SpamSettings') || {})[:enable_spam_protection]

    # Check comment for spam using Akismet
    is_spam_comment_akismet?(author, text)
  end

  def is_spam_comment_akismet?(author, text)
    akismet = Akismet.new(AppConfig[:akismet_key], AppConfig[:akismet_url])

    # Check whether key is valid
    unless akismet.verifyAPIKey
      puts 'WARNING: Akismet key is not valid.'
      return true
    end

    # Check comment, returning true when comment is spam
    akismet.commentCheck(
      request.remote_ip,            # remote IP
      request.user_agent,           # user agent
      request.env['HTTP_REFERER'],  # http referer
      request.request_uri,          # permalink
      'comment',                    # comment type
      author,                       # author name
      '',                           # author email
      '',                           # author url
      text,                         # comment text
      {}                            # other
    )
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
