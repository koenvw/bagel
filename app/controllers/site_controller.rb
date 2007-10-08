class SiteController < ApplicationController

  before_filter :redirect_to_default_website
  before_filter :check_splash

  attr_accessor :content_for_layout
  attr_accessor :content_type
  attr_accessor :content_title

  @@dont_do_splash = false

  #no login required
  before_filter :check_authentication, :only => :nothing

  # routing is set up like this:
  # 1/ for the root (/)
  #  --> Show list of websites if the HTTP_HOST is not a configured website
  #  else --> show the website
  # 2/ for the content:
  #  --> /:site/show/:content_type/:id should always work
  #  --> /show/:content_type/:id will look at HTTP_HOST to figure out the correct website

  ########## RENDERING CONTENT

  # route '/' is set to root, not index
  def root
    # show the website index page if we can figure out in which site we are.
    if figure_out_site
      index
    else
      # nothing found ... show the list of websites
      str = ''
      Website.find(:all).each do |website|
        str << "<li><a href=\"/#{website.name}/index\">#{website.name}</a></li>"
      end
      render :text => "Website not found. Please select: <ul>#{str}<li><a href=\"/admin\">Admin</a></li></ul>"
    end
  end

  def index
    # find the appropiate generator
    gen = Generator.find_by_name_and_website_id(site+"_index_layout",site_id)
    if gen.nil?
      logger.warn "BAGEL::SiteController.index => Generator '#{site+"_index_layout"}' not found"
      render :text => "#{site} #{site_id}"
      #render_404 and return
    else
      case gen.templating_engine
      when 'liquid'
        on_liquid_stack(gen.name) do
          begin
            # Build assigns
            misc_assigns = {
              'path_info'       => request.path_info
            }
            assigns = {
              'data'            => DataDrop.new(assigns_for_generator(gen, misc_assigns)),
              'site_controller' => SiteControllerDrop.new(self, params)
            }

            # Render
            render :text => liquid_template(gen, assigns)
          rescue => exception
            handle_liquid_exception(exception, self, request)
          end
        end
      when 'erb'
        begin
          render :inline => gen.template
        rescue => exception
          handle_erb_exception(exception, gen)
        end
      end
    end
  end

  def content

    # Require both id and type
    render_404 and return if params[:id].nil?
    render_500 and return if params[:type].nil?

    @content_type = params[:type].downcase

    # Find requested item
    # FIXME: :type is not a good name => :content_type ?
    case params[:type].downcase
    when 'news'
      @news = News.find(params[:id])
      render_404 and return if @news.nil?
      @content_title = @news.title
      @content_generator, @content_for_layout = @news.template(site_id)
    when 'form'
      @form = Form.find(params[:id])
      render_404 and return if @form.nil?
      @content_title = @form.name
      @content_generator, @content_for_layout = @form.template(site_id)
    when 'generator' # Slightly custom
      @generator = Generator.find_by_name(params[:id])
      render_404 and return if @generator.nil?
      @content_title = "" # Empty, because users don't really want a <title></title>
      @content_generator = @generator
      @content_for_layout = @content_generator.template
    when 'container'
      @container = Container.find(params[:id])
      render_404 and return if @container.nil?
      @content_title = @container.title
      @content_generator, @content_for_layout = @container.template(site_id)
    when 'event'
      @event = Event.find(params[:id])
      render_404 and return if @event.nil?
      @content_title = @event.title
      @content_generator, @content_for_layout = @event.template(site_id)
    else
      render :text => "no such content type", :status => "404" and return
    end

    item = instance_variable_get("@"+@content_type)
    @content = item

    # Check whether item is published
    unless item.nil? or params.has_key?(:preview)
      # generators don't have sitems
      if item.class != Generator && item.respond_to?(:sitems)
        render_404 and return unless item.is_published?(site_id)
      end
    end

    # Format mapping
    formats = {
      'html' => 'text/html',
      'xml'  => 'text/xml',
      'css'  => 'text/css',
      'js'   => 'application/x-javascript'
    }

    # Render the content
    if @content_generator.templating_engine == 'liquid'
      # Liquid

      on_liquid_stack(@content_generator.name) do
        begin
          # Create assigns hash (item, content_title, content_for_layout, content_type)
          misc_assigns = {
            'content_type'  => lambda { @content_type },
            'content_title' => lambda { @content_title },
            'content'       => lambda { @content },
            'path_info'     => lambda { request.path_info }
          }

          # Convert assigns to a DataDrop used for delaying queries to the point where they're actually needed
          assigns = {
            'data' => DataDrop.new(assigns_for_generator(@content_generator, misc_assigns))
          }

          # The site controller is passed to the cache tag, because only site controller
          # can actually use write_fragment and read_fragment... not very pretty but it works
          assigns.merge!({
            'site_controller' => SiteControllerDrop.new(self, params)
          })

          if !params[:print].nil? || params[:type] == "splash"
            # no layout view
            render :text => Liquid::Template.parse(@content_for_layout).render!(assigns)
          elsif !params[:generator].nil?
            # preview
            render :text => Liquid::Template.parse(params[:generator][:template]).render!(assigns)
          elsif formats.keys.include?(params[:format])
            # HTML, XML, CSS, JS
            response.headers["Content-Type"] = formats[params[:format]]
            render :text => Liquid::Template.parse(@content_for_layout).render!(assigns), :type => params[:format].to_sym
          else # *_content_layout
            # Find generator
            gen = Generator.find(:first, :conditions => [ 'name=? AND website_id=?', "#{site}_content_layout", site_id ])
            render :text => "BAGEL::SiteController.index => Generator '#{site}_content_layout' not found" and return if gen.nil?

            # Build assigns
            rendered_content_for_layout = liquid_template(@content_generator, assigns, @content_for_layout)
            assigns = assigns.merge('content_for_layout' => rendered_content_for_layout)

            # Render
            render :text => liquid_template(gen, assigns)
          end
        rescue => exception
          handle_liquid_exception(exception, self, request)
        end
      end
    else
      # eRuby
      if !params[:print].nil? || params[:type] == "splash"
        # no layout view
        render :inline => @content_for_layout
      elsif !params[:generator].nil?
        # preview
        render :inline => params[:generator][:template]
      elsif formats.keys.include?(params[:format])
        # HTML, XML, CSS, JS
        response.headers["Content-Type"] = formats[params[:format]]
        begin
          render :inline => @content_for_layout, :type => params[:format].to_sym
        rescue => exception
          handle_erb_exception(exception, @content_generator)
        end
      else # *_content_layout
        # Find generator
        gen = Generator.find(:first, :conditions => [ 'name=? AND website_id=?', "#{site}_content_layout", site_id ])
        render :text => "BAGEL::SiteController.index => Generator '#{site}_content_layout' not found" and return if gen.nil?

        # Render
        begin
          render :inline => gen.template
        rescue => exception
          handle_erb_exception(exception, @content_generator)
        end
      end
      # something went wrong ...
      render_500 unless performed?
    end

  end

  ########## RENDERING OTHER CONTENT

  def media_item_from_db
    # Figure out disposition
    disposition = (params[:disposition] || 'inline')

    # Find image
    if params[:thumbnail].blank?
      media_item = MediaItem.find(params[:id])
    else
      media_item = MediaItem.find_by_parent_id_and_thumbnail(params[:id], params[:thumbnail])
    end

    # Find data for image
    media_item_data = DbFile.find(media_item.db_file_id).data

    # Send image data
    send_data(media_item_data, :type => media_item.content_type, :disposition => disposition)
  end

  def render_generator(generator, locals = {})
    # Find generator
    if AppConfig[:perform_caching]
      gen = Cache.get(generator)
      if gen.nil?
        gen = Generator.find_by_name(generator)
        Cache.put(generator,gen,5) # expiry is in seconds
      end
    else
      gen = Generator.find_by_name(generator)
    end

    # Make sure there is a generator
    return "can not find generator '#{generator}'" if gen.nil?

    case gen.templating_engine
    when 'liquid'
      on_liquid_stack(gen.name) do
        begin
          assigns = {
            'data'            => DataDrop.new(assigns_for_generator(gen)),
            'site_controller' => SiteControllerDrop.new(self, params)
          }
          str = liquid_template(gen, assigns)
        rescue => exception
          handle_liquid_exception(exception, self, request)
        end
      end
    when 'erb'
      begin
        str = render_to_string :inline => gen.template, :locals => locals
      rescue => exception
        str = handle_erb_exception(exception, gen, :return)
      end
      return str
    end

    # Done
    str
  end

  ########## MISC HELPERS

  def handle_erb_exception(exception,generator, render_or_return = :render)
    str = "<div class=\"templateError\"><pre>error processing '#{generator.name}': #{ERB::Util.html_escape(exception.message)}<br/>#{exception.backtrace.reject {|line| !line.starts_with?("compiled")}.join("<br/>")}</pre></div>"
    if local_request?
      if render_or_return == :render 
          render :text => str
      else
          return str
      end
    else
      bagel_log :exception => exception, :severity => :high, :extra_info => {:message => str}, :kind => 'exception', :request_url => "#{current_domain}#{request.env["PATH_INFO"]}" and return ""
    end
  end

  def global_assigns(other={})
    gen = Generator.find(:first, :conditions => [ 'name=? AND website_id=?', "#{site}_liquid_globals", site_id ])
    if !gen.nil? and gen.templating_engine == 'liquid'
      gen.assigns_as_hash(other).merge('flash' => flash.inject({}) { |memo, (key, value)| memo.merge({ key.to_s => value }) })
    else
      {}
    end
  end

  def assigns_for_generator(gen, existing_assigns={})
    globals = global_assigns(existing_assigns)

    data_assigns = {}
    data_assigns.merge!(globals)
    data_assigns.merge!(gen.assigns_as_hash(globals, existing_assigns))
    data_assigns.merge!(existing_assigns)

    data_assigns
  end

  def handle_liquid_caching(name, options, cache_binding, params)
    # Read cache
    cache = read_fragment(name, options)

    # Check whether we should load a cached version
    if cache.nil? or params[:clear]
      # Render content and cache it
      output = eval('super(context)', cache_binding)
      write_fragment(name, output, options)
    else
      # Load output from cache
      output = cache
    end

    # Return output
    output
  end

  def include_template(template_name, locals = {})
    render_generator(template_name, locals)
  end

  ########## FORM HANDLING

  def submit
    @formdef = FormDefinition.find(params[:id])
    if @formdef.nil? or params[:form].nil? 
      flash[:errors] = ["form definition not found or params[:forms] empty"]
      redirect_to_back_or_home and return
    end

    # check input
    if params[:form].to_a.select { |el| el[0].match(/required/) && el[1] == "" }.size > 0
      flash[:errors] = ["required fields are empty"]
      redirect_to_back_or_home and return
    end
    # remove "required" from input fields
    params_stripped = {}
    params[:form].each { |key,value| params_stripped[key.to_s.gsub("-required","").to_sym] = value }
    params[:form] = params_stripped

    # want some action ? punk...
    case @formdef.action
      when "remove_as_site_user"
        unless params[:form][:name].nil?
          su = SiteUser.find_by_email(params[:form][:name])
          unless su.nil?
            su.active = false
            su.save
          end
        end

      when "store_as_site_user"
        su = SiteUser.find_by_email(params[:form][:email].downcase)
        if su.nil?
          su = SiteUser.create :email => params[:form][:email].downcase, :active => true
          # default to hidden for all sites
          su.sitems.each { |sitem| sitem.is_published = false }
          su.save
        end
        su.name = params[:form][:name]
        # put this website status to published for this user
        website_id = params[:website_id]
        if website_id.nil?
          flash[:errors] = ["website not found, please contact the administrator"]
          redirect_to_back_or_home and return
        else
          website_id = website_id.to_i
        end
        unless website_id > 0
          flash[:errors] = ["website not found, please contact the administrator"]
          redirect_to_back_or_home and return
        end
        sitem = su.add_sitem_unless(website_id)
        # set extra tags, if any
        params[:tags].each do |key,value|
          tag = Tag.find(value)
          if params[:form][key.to_sym] == "1"
            su.add_tag_unless(tag)
          else
            su.remove_tag_unless(tag)
          end
        end
        # set user active
        su.active = true
        # flash errors, if any
        @su = su
        #render :inline => "<%= debug @su %>" and return
        if su.save
          #FIXME: why status was reset on su.save ???
          sitem.is_published = true
          sitem.save
        else
          flash[:errors] = su.errors.full_messages
          redirect_to_back_or_home and return
        end
        if sitem.nil?
          flash[:errors] = ["website not found, please contact the administrator"]
          redirect_to_back_or_home and return
        end

      # FIXME: auto55-specific
      when "store_as_site_link"
        @link=Link.new
        @link.title=params[:form][:name]
        @link.url=params[:form][:link]

        if @link.save == false
          flash[:errors] = @link.errors.full_messages
          redirect_to_back_or_home and return
        else
          @link.add_tag_unless(Tag.find(params[:cat_id]))
          sitem = @link.add_sitem_unless(params[:website_id])
          @link.save
          @link.sitems.delete_all

          @link.create_in_sitems :is_published => false,:website_id=>params[:website_id],:name=> params[:form][:name]
          flash[:errors] = ["Toevoeging link compleet"]
          redirect_to params[:return] and return
        end

    end

    # Create the form
    @form = Form.new
    @form.form_definition_id = @formdef.id
    @form.name = params[:form][:name]
    @form.data = params[:form]
    @form.form = @formdef.template

    # Find the to address
    params[:to] = params[:form][:to] if params[:to].nil?
    params[:to] = params[:form][:email] if params[:to].nil?
    params[:to] = params[:form][:name] if params[:to].nil?

    # Check for spam
    if is_spam_comment?(params[:to], params[:form].to_s)
      flash[:error] = 'Your comment was registered as spam. Please make sure everything you entered doesn\'t look like spam. Sorry. :)'
      redirect_to_back_or_home
      return
    end

    # Save it
    if @form.save
      unless params[:mail_generator_name].nil?
        mail_generator = Generator.find_by_name(params[:mail_generator_name])
        render :text => "generator '#{params[:mail_generator_name]}' not found" and return if mail_generator.nil?
        params[:body] = mail_generator.template

        # check email adres
        if !params[:to].nil? && !params[:to].match(AppConfig[:email_expression])
          flash[:errors] = ["email adres not valid or fields are empty"]
          redirect_to_back_or_home and return
        end
        if !params[:email].nil? && !params[:email].match(AppConfig[:email_expression])
          flash[:errors] = ["email adres not valid or fields are empty"]
          redirect_to_back_or_home and return
        end

        # send mail
        # params: options[:form], options[:body], options[:subject], options[:to], options[:from]
        params[:content_type] ||= "text/html"
        ApplicationMailer.deliver_template_mail(params)

      end

      # we are done here ... redirect the user
      if @formdef.redirect_to == ""
        redirect_to_back_or_home
      else
        redirect_to @formdef.redirect_to
      end

    else
      flash[:errors] = ["error processing form. please contact the administrator"]
      redirect_to_back_or_home
    end

  end

  def print_routes
    #FIXME: move this to admin/
    render :inline => "<pre><% ActionController::Routing::Routes.routes.each do |r| %><%= r %>\n<% end %></pre>" unless AdminUser.current_user.nil?
  end

  def set_default_website
    # Check whether we have a site set
    redirect_to_back_or_home and return if params[:new_site].nil?

    # Find website ID for name
    website_id = get_website_id(params[:new_site])
    redirect_to_back_or_home and return if website_id == nil

    # Find website
    website = Website.find(website_id)

    # Set cookie
    cookies[:default_website] = { :value => params[:new_site], :domain => website.domain, :expires => 5.years.from_now }

    # Done
    if website.domain == ""
      redirect_to "/#{cookies[:default_website]}"
    else
      redirect_to website.domain
    end
  end

  def redirect_to_back_or_home
    redirect_to (request.env["HTTP_REFERER"].nil? ? '/' : :back)
  end

  def redirect_to_default_website
    #
    @@dont_do_splash = false
    # check: do we have a cookie
    return if cookies[:default_website].nil?
    # check: are we on the same website as our cookie ?
    return if site == cookies[:default_website]

    # check the cookie, to see if it has a valid website
    website_id = get_website_id(cookies[:default_website])
    if website_id == nil
      # BAD COOKIE !
      cookies[:default_website] == nil
    else
      # are we not setting the cookie ?
      if params[:new_site].nil?
        # do not redirect to splash to avoid double render error
        # check will be shown when we are on the default website
        # FIXME: skip_before_filter is a class method
        #skip_before_filter :check_splash
        @@dont_do_splash = true

        # follow the cookie !
        website = Website.find(website_id).domain

        if website == ""
          redirect_to "/#{cookies[:default_website]}"
        else
          redirect_to website
        end
      end
    end
  end

  def check_splash
    return if @@dont_do_splash
    splash_setting = Setting.get_cached('Splash Page')
    return if site.nil?
    return if splash_setting.nil?
    return if splash_setting[site.to_sym].nil?
    return if splash_setting[site.to_sym][:goto].nil?

    # setting looks ok ... fetch urls
    goto = splash_setting[site.to_sym][:goto]
    current_url = request.env['PATH_INFO']

    # check cookie
    return unless cookies[goto.rubify.to_sym].nil?
    # check exceptions
    match_array = ""
    unless splash_setting[site.to_sym][:exceptions].nil?
      match_array = splash_setting[site.to_sym][:exceptions].select { |name,regex| true if current_url.match regex }
    end

    # redirect unless we've matched an exception
    # FIXME: add more user_agents
    if match_array.size == 0 and (!request.env['HTTP_USER_AGENT'].nil? and request.env['HTTP_USER_AGENT'].match("Googlebot").nil?)
      cookies[goto.rubify.to_sym] = "1"
      redirect_to add_referrer_to_url(goto) and return
    end
  end

private

  def add_referrer_to_url(url)
    current_url = request.env['PATH_INFO']
    url_split = url.split("?")
    if url_split.size == 1
      return url_for(:controller => url_split[0], :referrer => current_url)
    else
      querystring_split = url_split[1].split("=")
      return url_for(:controller => url_split[0], querystring_split[0].to_sym => querystring_split[1], :referrer => current_url)
    end
  end

public

  ########## DEPRECATED

  def render_content(cls)
    $stderr.puts 'DEPRECATION WARNING: SiteController#render_content() is deprecated.'
    render_to_string :inline => cls.template(site_id)
  end

  def link_to_content(name, options = {}, html_options = nil, *parameters_for_method_reference)
    $stderr.puts 'DEPRECATION WARNING: SiteController#link_to_content() is deprecated.'
    link_to(name, options = {}, html_options = nil, *parameters_for_method_reference)
  end

end
