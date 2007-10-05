module Admin::FormsHelper

  def bagel_text_field(method, options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << text_field(:form, method, options)
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end
    out << '</fieldset>'
  end

  def bagel_auto_complete_field(method, options = {}, completion_options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << text_field_with_auto_complete(:form, method, options, completion_options)
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end    
    out << '</fieldset>'
  end

  def bagel_text_area(method, options = {})
    options[:class] = "mceNoEditor"
    options[:rows] = 5
    options[:cols] = 40
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << text_area(:form, method, options)
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end    
    out << '</fieldset>'
  end

  def bagel_rich_text_area(method, options = {})
    options[:class] = 'text_area_large'
    out = '<div class="mceFrame">'
    out << text_area(:form, method, options)
    out << '</div>'
    out << '<br />'
    if !options[:help].blank?
      out << '<p class="mcehelp">'+ options[:help] +'</p>'
    end
    return out
  end

  def bagel_check_box(method, options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << check_box(:form, method, options)
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end
    out << '</fieldset>'
  end

  def bagel_select_field(method, options = {}, html_options = {})
    choices = options[:values]
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << select(:form, method, choices, options, html_options)
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end     
    out << '</fieldset>'
  end

  def bagel_country_select(method, priority_countries = nil, options = {}, html_options = {})
    options[:include_blank] = true
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << country_select(:form, method, priority_countries, options, html_options)
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end    
    out << '</fieldset>'
  end

  def bagel_google_map(method, options = {})
    form_settings = Setting.get("FormSettings") || {}
    google_maps_key = form_settings[:google_maps_key] || "ABQIAAAAkFl4zo_XLubPzqJVuMDFvBTJQa0g3IQ9GZqIMmInSLzwtGDKaBSLp8ScqaRZ5Opk5TOqbqjFG4YDsw" # http://localhost
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << '<script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key='+ google_maps_key +'" type="text/javascript"></script>'
    out << javascript_include_tag("google_map", :plugin => :bagel)
    #out << javascript_tag("bagel_googleMap(#{@form.latitude},#{@form.longitude});")
    #out << javascript_tag("bagel_googleMap();")
    out << hidden_field(:form, :latitude)
    out << hidden_field(:form, :longitude)
    out << '<div id="map" style="width: 550px; height: 300px; float: left;"></div>'
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end    
    out << '</fieldset>'
  end

  def bagel_admin_user_select(method, options = {}, html_options = {})
    choices = AdminUser.find(:all, :order => "firstname").map { |user| [user.fullname, user.id] }
    options[:include_blank] = true
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << select(:form, method, choices, options, html_options)
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end     
    out << '</fieldset>'
  end

  def bagel_date_field(method, options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << calendar_field_tag("form[#{method}]", @form.send(method),true, true, { :class => "date" }, {:showOthers => true, :showsTime => false})
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end     
    out << '</fieldset>'
  end

  def bagel_date_time_field(method, options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << calendar_field_tag("form[#{method}]", @form.send(method),true, true, { :class => "date" }, {:showOthers => true, :showsTime => true})
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end     
    out << '</fieldset>'
  end

  def bagel_boolean_field(method, options = {}, html_options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
    out << select(:form, method, ["no","yes"], options, html_options)
    if !options[:help].blank?
      out << '<p class="help">'+ options[:help] +'</p>'
    end    
    out << '</fieldset>'
  end

  def bagel_slider_for(name, *args, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    #FIXME
    #start = '<div class="subContent"><a href="#" class="openClose">Open</a><h3 class="forClose">Image versions</h3><div class="collapsed" style="display: none;"> hello'
    #concat(start, proc.binding)
    #fields_for(object_name, *(args << options), &proc)
    #stop = '<div class="bottom"></div></div>'
    #concat(stop, proc.binding)
 end

end
