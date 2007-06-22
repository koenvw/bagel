class SiteController < ApplicationController
  before_filter :redirect_to_default_website
  before_filter :check_splash
  #FIXME: this won't work on http://localhost
  #before_filter :domain_lock
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
  #

  # route '/' is set to root, not index
  def root
    # if the HTTP_HOST is known to be a website
    unless Website.find_by_name(site).nil?
      index
    else
      # ... show the list of websites
      str = ''
      Website.find(:all).each do |website|
        str << "<a href=\"/#{website.name}/index\">#{website.name}</a> | "
      end
      render :text => str + "<a href=\"/admin\">Admin</a>"
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
      render :inline => gen.template
    end
  end


  def content

    # cleanup param id => MAJOR GOTCHA?
    #params[:id] = params[:id].scan(/(\d+|w+)/).first

    render_404 and return if params[:id].nil?
    render_500 and return if params[:type].nil?

    @content_type = params[:type].downcase

    # FIXME: rails 1.2 seperates route on dots so :id will never have an extension?
    params_id = File.basename(params[:id], File.extname(params[:id]))

    #click_counts are updated in .template() (ActsAsContentType)
    case params[:type].downcase
    when 'page'
      @page = Page.find(:first,:include=>:sitems,:conditions => ['website_id=? AND name=?', site_id,params_id]) if params_id.to_i == 0 #FIXME: this will not work if site_id is bad
      @page = Page.find(params_id)          if params_id.to_i != 0
      if @page.nil?
        logger.warn "BAGEL::SiteController.index => Page '#{params_id}'not found"
        render_404 and return
      end
      @content_for_layout = @page.template(site_id)
      @content_title = @page.title.rubify

    when 'news'
      @news = News.find(params_id)
      render_404 and return if @news.nil?
      @content_for_layout = @news.template(site_id)
      @content_title = @news.title.rubify

    when 'form'
      @form = Form.find(params_id)
      render_404 and return if @form.nil?
      @content_for_layout = @form.template(site_id)
      @content_title = @form.name.rubify

    when 'form_definition'
      @formdef = FormDefinition.find_by_name(params_id) if params_id.to_i == 0
      @formdef = FormDefinition.find(params_id) if params_id.to_i != 0
      render_404 and return if @formdef.nil?
      str = ''
      str << "<%= start_form_tag :controller => 'site', :action => 'submit', :id => @formdef %>"
      str << @formdef.template_form(site_id)
      str << "<%= end_form_tag %>"
      @content_for_layout = str
      @content_title = @formdef.name.rubify

    when 'generator'
      @generator = Generator.find_by_name(params_id)
      if @generator.nil?
        logger.warn "BAGEL::SiteController.index => generator '#{params_id}'not found"
        render_404 and return
      end
      @content_for_layout =  @generator.template
      @content_title = @generator.name.rubify

    when 'book'
      @book = Book.find(params_id)
      render_404 and return if @book.nil?
      @content_for_layout = @book.template(site_id)
      @content_title = @book.title.rubify

    when 'test_article'
      @test_article= TestArticle.find(params_id)
      render_404 and return if @test_article.nil?
      @content_for_layout = @test_article.template(site_id)
      @content_title = @test_article.title.rubify

    when 'gallery'
      @gallery= Gallery.find(params_id)
      render_404 and return if @gallery.nil?
      @content_for_layout = @gallery.template(site_id)
      @content_title = @gallery.title.rubify

    when 'video'
      @video= Video.find(params_id)
      render_404 and return if @video.nil?
      @content_for_layout = @video.template(site_id)
      #@content_title = @video.title.rubify
    else
      render :text => "no such contenttype", :status => "404" and return
    end

    # published or not
    item=instance_variable_get("@"+@content_type)
    unless item.nil? or params.has_key?(:preview)
      # generators don't have sitems
      if item.class != Generator && item.respond_to?(:sitems)
        logger.warn "BAGEL::SiteController.index => item is not published"
        render_404 and return unless item.is_published?(site_id)
      end
    end

    # render the content
    if !params[:print].nil? || params[:type] == "splash"
      # no layout view
      render :inline => @content_for_layout
    elsif !params[:generator].nil?
      # preview
      render :inline => params[:generator][:template]
    elsif params[:format] == "html"
      # HTML
      response.headers["Content-Type"] = "text/html"
      render :inline => @content_for_layout, :type => :html
    elsif params[:format] == "xml"
      # XML
      response.headers["Content-Type"] = "text/xml"
      render :inline => @content_for_layout, :type => :xml
    elsif params[:format] == "css"
      # CSS
      response.headers["Content-Type"] = "text/css"
      render :inline => @content_for_layout, :type => :css
    elsif params[:format] == "js"
      # JS
      response.headers["Content-Type"] = "application/x-javascript"
      render :inline => @content_for_layout, :type => :js
    else
      # normal
      gen = Generator.find(:first, :conditions =>["name=? AND website_id=?",site + "_content_layout",site_id])
      if gen.nil?
        render :text => "BAGEL::SiteController.index => Generator '#{site+"_content_layout"}' not found" and return
      else
        render :inline => gen.template
      end
    end
  end

  #template methods
  def render_content(cls)
    # FIXME: where is this used?
    render_to_string :inline => cls.template(site_id)
  end

  def include_template(template_name, locals = {})
    render_generator(template_name, locals)
  end

  def render_generator(generator, locals = {})
    if AppConfig[:perform_caching]
      gen = Cache.get(generator)
      if gen.nil?
        gen = Generator.find_by_name(generator)
        Cache.put(generator,gen,5) # expiry is in seconds
      end
    else
      gen = Generator.find_by_name(generator)
    end
    if gen.nil?
      str = "can not find generator '#{generator}'"
    else
      str = render_to_string :inline => gen.template, :locals => locals
    end
    return str
  end
  
  def link_to_content(name, options = {}, html_options = nil, *parameters_for_method_reference)
    #FIXME: this is never used ?
    if options.has_key?(:sobject_id)
    end
    link_to(name, options = {}, html_options = nil, *parameters_for_method_reference)
  end

  #form handling
  def submit
    @formdef = FormDefinition.find(params[:id])
    redirect_to_back_or_home and return if @formdef.nil? or params[:form].nil?

       # check input
    if params[:form].to_a.select { |el| el[0].match(/required/) && el[1] == "" }.size > 0
      flash[:errors] = ["required fields are empty"]
      redirect_to_back_or_home and return
    end
    # check for spam via akismet
    # FIXME!
    #if check_comment_for_spam(@comment.author, @comment.comment_text)
    #  flash[:errors] = ["spam!"]
    #  redirect_to_back_or_home and return
    #end
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
          #unless su.nil?
          #  su.sitems.each { |sitem| sitem.status = "Hidden"; sitem.save }
          #end
        end

      when "store_as_site_user"
        su = SiteUser.find_by_email(params[:form][:email].downcase)
        if su.nil?
          su = SiteUser.create :email => params[:form][:email].downcase, :active => true
          # default to hidden for all sites
          su.sitems.each { |sitem| sitem.status = "Hidden" }
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
          sitem.status = "1"
          sitem.save
        else
          flash[:errors] = su.errors.full_messages
          redirect_to_back_or_home and return
        end
        if sitem.nil?
          flash[:errors] = ["website not found, please contact the administrator"]
          redirect_to_back_or_home and return
        end

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

          @link.create_in_sitems :status=>'Hidden',:website_id=>params[:website_id],:name=> params[:form][:name]
          flash[:errors] = ["Toevoeging link compleet"]
          redirect_to params[:return] and return
        end

    end

    # save the form
    @form = Form.new
    @form.form_definition_id = @formdef.id
    @form.name = params[:form][:name]
    @form.data = params[:form]
    @form.form = @formdef.template
    if @form.save

      unless params[:mail_generator_name].nil?
        mail_generator = Generator.find_by_name(params[:mail_generator_name])
        render :text => "generator '#{params[:mail_generator_name]}' not found" and return if mail_generator.nil?
        params[:body] = mail_generator.template

        # see where we can find the to: adres
        params[:to] = params[:form][:to] if params[:to].nil?
        params[:to] = params[:form][:email] if params[:to].nil?
        params[:to] = params[:form][:name] if params[:to].nil?

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
        ApplicationMailer.queue = false
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

  def set_default_website
    # do we have a site ?
    redirect_to_back_or_home and return if params[:new_site].nil?
    # check the site, to see if its valid
    website_id = get_website_id(params[:new_site])
    if website_id == nil
      # BAD SITE !
      redirect_to_back_or_home
    else
      # set cookie and redirect
      # FIXME: project specific => auto55.be
      cookies[:default_website] = { :value => params[:new_site], :domain => "auto55.be", :expires => 5.years.from_now }
      website = Website.find(website_id).domain
      if website == ""
        redirect_to "/#{cookies[:default_website]}"
      else
        redirect_to website
      end
    end
  end

  def redirect_to_back_or_home
    if request.env["HTTP_REFERER"].nil?
      redirect_to "/"
    else
      redirect_to :back
    end
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

  def triggergc

    GC.start
    render :inline => "<%= debug request %>" and return
    render :text => "garbage collected"
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

end
