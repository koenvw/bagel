module Admin::FormsHelper

  def bagel_dyn_field(field_type, object_name, method, options, other1= {}, other2= {})
    case field_type
      when :text_field
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << text_field(object_name, method, options)
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :auto_complete_field
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << text_field_with_auto_complete(object_name, method, options, other1)
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :text_area
        options[:class] = "mceNoEditor"
        options[:rows] = 5
        options[:cols] = 40
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << text_area(object_name, method, options)
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :rich_text_area
        options[:class] = 'text_area_large'
        out = '<div class="mceFrame">'
        out << text_area(object_name, method, options)
        out << '</div>'
        out << '<br />'
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?

      when :check_box
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << check_box(object_name, method, options)
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :select_field
        choices = options[:values]
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << select(object_name, method, choices, options, other1)
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :country_select
        options[:include_blank] = true
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << country_select(object_name, method, options, other1, other2)
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :google_map
        form_settings = Setting.get("FormSettings") || {}
        google_maps_key = form_settings[:google_maps_key] || "ABQIAAAAkFl4zo_XLubPzqJVuMDFvBTJQa0g3IQ9GZqIMmInSLzwtGDKaBSLp8ScqaRZ5Opk5TOqbqjFG4YDsw" # http://localhost
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << '<script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key='+ google_maps_key +'" type="text/javascript"></script>'
        out << hidden_field(object_name, :latitude)
        out << hidden_field(object_name, :longitude)
        out << '<div id="map" style="width: 550px; height: 300px; float: left;"></div>'
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :admin_user_select
        choices = AdminUser.find(:all, :order => "firstname").map { |user| [user.fullname, user.id] }
        options[:include_blank] = true
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << select(object_name, method, choices, options, other1)
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :date_field
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << calendar_field_tag("#{object_name}[#{method}]", self.instance_variable_get("@#{object_name}").send(method),true, true, { :class => "date" }, {:showOthers => true, :showsTime => false})
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :date_time_field
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << calendar_field_tag("#{object_name}[#{method}]", self.instance_variable_get("@#{object_name}").send(method),true, true, { :class => "date" }, {:showOthers => true, :showsTime => true})
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'

      when :boolean_field
        out = '<fieldset class="oneline">'
        out << '<label for="form_definition_action">' + (options[:label] || method.to_s.capitalize) + '</label>'
        out << select(object_name, method, ["no","yes"], options, other1)
        out << '<p class="help">'+ options[:help] +'</p>' unless options[:help].blank?
        out << '</fieldset>'
      end
  end

  def bagel_text_field(method, options = {})
    bagel_dyn_field (:text_field, :form, method, options)
  end

  def bagel_auto_complete_field(method, options = {}, completion_options = {})
    bagel_dyn_field(:auto_complete_field, :form, method, options, completion_options)
  end

  def bagel_text_area(method, options = {})
    bagel_dyn_field(:text_area, :form, method, options)
  end

  def bagel_rich_text_area(method, options = {})
    bagel_dyn_field(:rich_text_area, :form, method, options)
  end

  def bagel_check_box(method, options = {})
    bagel_dyn_field(:check_box, :form, method, options)
  end

  def bagel_select_field(method, options = {}, html_options = {})
    bagel_dyn_field(:select_field, :form, method, options)
  end

  def bagel_country_select(method, priority_countries = nil, options = {}, html_options = {})
    bagel_dyn_field(:country_select, :form, method, priority_countries, options, html_options)
  end

  def bagel_google_map(method, options = {})
    bagel_dyn_field(:google_map, :form, method, options)
  end

  def bagel_admin_user_select(method, options = {}, html_options = {})
    bagel_dyn_field(:admin_user_select, :form, method, options)
  end

  def bagel_date_field(method, options = {})
    bagel_dyn_field(:date_field, :form, method, options)
  end

  def bagel_date_time_field(method, options = {})
    bagel_dyn_field(:date_time_field, :form, method, options)
  end

  def bagel_boolean_field(method, options = {}, html_options = {})
  end

end
