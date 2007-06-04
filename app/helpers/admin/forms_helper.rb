module Admin::FormsHelper

  def bagel_text_field(object_name, method, options = {})
    out = '<fieldset class="oneline">'
    out << '<label for="form_definition_action">' + method.to_s + '</label>'
    out << text_field(object_name, method, options = {})
    out << '</fieldset>'
  end

end
