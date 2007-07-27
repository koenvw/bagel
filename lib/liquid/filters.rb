module BagelFilters

  # Returns the input, HTML-escaped
  def html_escape(input)
    input.blank? ? '' : input.gsub('&', '&amp;').
                              gsub('<', '&lt;').
                              gsub('>', '&gt;').
                              gsub('\'', '&apos;').
                              gsub('"', '&quot;')
  end

  # Returns an array of relationships of the given name
  def relationships_with_name(input, name)
    input.relations(name)
  end

end

Liquid::Template.register_filter(BagelFilters)
