module Admin::FormsHelper

  def bagel_text_field(method, options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + method.to_s + '</label>'
    out << text_field(:form, method, options)
    out << '</fieldset>'
  end

  def bagel_text_area(method, options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + method.to_s + '</label>'
    out << text_area(:form, method, options)
    out << '</fieldset>'
  end
  
  def bagel_select_country(object, method, choices, options = {}, html_options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + method.to_s + '</label>'
    out << select(:form, method, choices, options, html_options)
    out << '</fieldset>'  end

  def bagel_google_map(method, options = {})

  end


end
