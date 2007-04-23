module BagelApplication

  def self.append_features(base)
    super
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
    end
  end
  
  module ClassMethods
    include ExceptionNotifiable

    @@site_id = {}  
    def bagel_application_setup
      filter_parameter_logging :password
      before_filter :check_authentication, :except => [ :login, :reset_password ]
      #before_filter :set_language
      hide_action :site,:site_id,:get_relation,:current_domain,:current_url
    end
    
    def tinymce_options
      {:options => {:theme => 'advanced',
                    :browsers => %w{msie gecko},
                    :convert_urls => false,
                    :theme_advanced_toolbar_location => "top",
                    :theme_advanced_toolbar_align => "left",
                    :theme_advanced_resizing => true,
                    :theme_advanced_resize_horizontal => false,
                    :paste_auto_cleanup_on_paste => true,
                    :theme_advanced_buttons1 => "bold,italic,underline,separator,strikethrough,bullist,numlist,link,image,separator,code,anchor,separator,pastetext,pasteword,selectall",
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
                    :paste_strip_class_attributes => "mso"}
      }
    end

  end
  
  module InstanceMethods
  
    public
    def content_types
      $stderr.puts('DEPRECATION WARNING: content_types can no longer be used. use ContentTypes.find(:all)')
      raise NotImplementedError.new("DEPRECATION WARNING: content_types can no longer be used. use ContentTypes.find(:all)")
    end
    
    def current_user
      $stderr.puts 'DEPRECATION WARNING: Application#current_user() is deprecated; use AdminUser#current_user() instead.'
      AdminUser.current_user
    end
    
    def site
      if params[:site].nil?
        # routing is virtual
        current_domain.domainify
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
      if AppConfig[:websites][website_name] == nil
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
      Relationship.find_by_from_sobject_id_and_category_id(item.sobject.id,Relation.find_by_name(relation_name).id)
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
  
    def paginate_collection(collection, options = {})
      default_options = {:per_page => 10, :page => 1}
      options = default_options.merge options
  
      pages = ActionController::Pagination::Paginator.new self, collection.size, options[:per_page], options[:page]
      first = pages.current.offset
      last = [first + options[:per_page], collection.size].min
      slice = collection[first...last]
      return [pages, slice]
      
    end


  
end
end