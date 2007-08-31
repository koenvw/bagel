require 'ipaddr'

module BagelApplication

  def self.append_features(base)
    super
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
    end
  end

  module ClassMethods

    ########## Bagel-specific

    @@site_id = {}
    def bagel_application_setup
      filter_parameter_logging :password
      before_filter :check_authentication, :except => [ :login, :reset_password ]
      #before_filter :set_language
      hide_action :site,:site_id,:get_relation,:current_domain,:current_url
    end

    def tinymce_options
      {:options => {:theme => 'advanced',
                    :editor_deselector => "mceNoEditor",
                    :browsers => %w{msie gecko},
                    :convert_urls => false,
                    :theme_advanced_toolbar_location => "top",
                    :theme_advanced_toolbar_align => "left",
                    :theme_advanced_resizing => true,
                    :theme_advanced_resize_horizontal => false,
                    :theme_advanced_buttons1 => "bold,italic,underline,separator,strikethrough,bullist,numlist,link,image,separator,code,anchor,separator,pastetext,pasteword,selectall,separator,formatselect",
                    :theme_advanced_buttons2 => "",
                    :theme_advanced_buttons3 => "",
                    :plugins => %w{contextmenu paste inlinepopups advimage advlink table},
                    :paste_create_paragraphs => true,
                    :paste_create_linebreaks => true,
                    :paste_use_dialog => false,
                    :paste_auto_cleanup_on_paste => true,
                    :paste_convert_middot_lists => true,
                    :paste_unindented_list_class => "unindentedList",
                    :paste_convert_headers_to_strong => true,
                    :paste_insert_word_content_callback => "convertWord",
                    :paste_remove_spans => true,
                    :paste_remove_styles => true,
                    :paste_strip_class_attributes => "mso"}.update(Setting.get("EditorSettings") || {})
      }
    end

    ########## Exception Notification

    def consider_local(*args)
      local_addresses.concat(args.flatten.map { |a| IPAddr.new(a) })
    end

    def local_addresses
      addresses = read_inheritable_attribute(:local_addresses)
      unless addresses
        addresses = [IPAddr.new("127.0.0.1")]
        write_inheritable_attribute(:local_addresses, addresses)
      end
      addresses
    end

    def exception_data(deliverer=self)
      if deliverer == self
        read_inheritable_attribute(:exception_data)
      else
        write_inheritable_attribute(:exception_data, deliverer)
      end
    end

  end

  module InstanceMethods

  public

    ########## Bagel-specific

    def bagel_log(*args)
      LogMessage.log(*args)
    end

    def site
      if params[:site].nil?
        # routing is virtual
        AppConfig[:domain_map].nil? ? current_domain.domainify : AppConfig[:domain_map][current_domain.domainify]
      else
        # follow the site that the route gave us
        params[:site]
      end
    end

    def current_domain
      request.env['HTTP_X_FORWARDED_HOST'] || request.env['HTTP_HOST']
    end

    def current_url
      url = "http://" + current_domain + request.env['PATH_INFO']
      url << "?" + request.env['QUERY_STRING'] unless request.env['QUERY_STRING'] == nil
      return url
    end

    # find the id for the given site.
    def site_id
      get_website_id(site)
    end

    # this method will return the website_id for a given website_name
    # will return nil if website_name is not found
    def get_website_id(website_name)
      website_id = nil
      if AppConfig[:websites].nil? || AppConfig[:websites][website_name] == nil
        # loop up website_id
        website = Website.find_by_name(website_name)
        website_id = website.id unless website.nil?
      else
        # return cached value if available
        website_id = AppConfig[:websites][website_name]
      end

      return website_id
    end

    # fetch the relationship for the given item and relationship name
    def get_relation(item, relation_name)
      Relationship.find_by_from_sobject_id_and_relation_id(item.sobject.id,Relation.find_by_name(relation_name).id)
    end

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

  protected

    def check_authentication
      if session[:admin_user].nil?
        session[:requested_page] = request.parameters
        redirect_to login_url
        return false
      end
    end

    def set_language
      unless session[:admin_user].nil?
        user = session[:admin_user]
        Locale.set(user.language_code)
      end
    end

   

  public
    def paginate_collection(collection, options = {})
      default_options = {:per_page => 10, :page => 1}
      options = default_options.merge options

      pages = ActionController::Pagination::Paginator.new self, collection.size, options[:per_page], options[:page]
      first = pages.current.offset
      last = [first + options[:per_page], collection.size].min
      slice = collection[first...last]
      return [pages, slice]

    end

    ########## Exception Notification

    def local_request?
      remote = IPAddr.new(request.remote_ip)
      !self.class.local_addresses.detect { |addr| addr.include?(remote) }.nil?
    end

    def render_404
      render :file => "#{RAILS_ROOT}/public/404.html", :status => "404 Not Found"
    end

    def render_500(to_string=false)
      if to_string
        render_to_string :file => "#{RAILS_ROOT}/public/500.html", :status => "500 Error"
      else
        render           :file => "#{RAILS_ROOT}/public/500.html", :status => "500 Error"
      end
    end

    def rescue_action_in_public(exception)
      # Gather data about exception
      session = request.session.instance_variables.inject({}) do |memo, var|
        memo.merge({ var => request.session.instance_variable_get(var) })
      end
      data = {
        :generator_backtrace => $_bagel_liquid_template_stack,
        :controller          => {
          :params              => params,
          :request             => request.params,
          :session             => session
        }
      }
      case exception
        when ActiveRecord::RecordNotFound, ActionController::UnknownController, ActionController::UnknownAction, ActionController::RoutingError
          render_404
          
          # Log exception
          bagel_log :exception => exception, :severity => :medium, :kind => '404', :extra_info => data, :hostname => request.host_with_port
        else          
          render_500

          # Log exception
          bagel_log :exception => exception, :severity => :high, :kind => 'exception', :extra_info => data, :hostname => request.host_with_port
      end
    end

    ########## DEPRECATED

    def content_types
      $stderr.puts('DEPRECATION WARNING: content_types can no longer be used. use ContentTypes.find(:all)')
      raise NotImplementedError.new("DEPRECATION WARNING: content_types can no longer be used. use ContentTypes.find(:all)")
    end

    def current_user
      $stderr.puts 'DEPRECATION WARNING: Application#current_user() is deprecated; use AdminUser#current_user() instead.'
      AdminUser.current_user
    end

  end

end
