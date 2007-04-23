module DatePickerHelper

  def date_picker_field_multi(object, method)
    object_name = object.sub(/\[\]$/,"")

    obj = instance_eval("@#{object_name}")
    value = obj.send(method) unless obj.nil?
    display_value = value.respond_to?(:strftime) ? value.strftime('%d %b %Y') : value.to_s
    display_value = '[ choose date ]' if display_value.blank?
    internal_value = value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : ""

    name = "#{object_name}[#{obj.id}][#{method}]"
    id = "#{object_name}_#{obj.id}_#{method}"

    out = tag("input", {:id => id, :name => name, :type=>"hidden", :value=> internal_value})
    out << content_tag('a', display_value, :href => '#',
        :id => "_#{id}_link", :class => '_demo_link',
        :onclick => "DatePicker.toggleDatePicker('#{id}'); return false;")
    out << tag('div', :class => 'date_picker', :style => 'display: none',
                      :id => "_#{id}_calendar")
    if obj.respond_to?(:errors) and obj.errors.on(method) then
      ActionView::Base.field_error_proc.call(out, nil) # What should I pass ?
    else
      out
    end


  end

  def date_picker_field(object, method)
    obj = instance_eval("@#{object}")
    value = obj.send(method) unless obj.nil?
    display_value = value.respond_to?(:strftime) ? value.strftime('%d %b %Y') : value.to_s
    display_value = '[ choose date ]' if display_value.blank?
    internal_value = value.respond_to?(:strftime) ? value.strftime('%d %b %Y') : value.to_s

    #out = hidden_field(object, method)
    out = tag("input", {:id => "#{object}_#{method}", :name => "#{object}[#{method}]", :type=>"hidden", :value=> internal_value})
    out << content_tag('a', display_value, :href => '#',
        :id => "_#{object}_#{method}_link", :class => '_demo_link',
        :onclick => "DatePicker.toggleDatePicker('#{object}_#{method}'); return false;")
    out << tag('div', :class => 'date_picker', :style => 'display: none',
                      :id => "_#{object}_#{method}_calendar")
    if obj.respond_to?(:errors) and obj.errors.on(method) then
      ActionView::Base.field_error_proc.call(out, nil) # What should I pass ?
    else
      out
    end
  end
end
