module Admin::ContentHelper

    def figure_out_edit_link(ctype)
        action = "edit"
        param_id = nil
        form_definition_id = nil
        type = ctype.core_content_type
        ctrl = type.tableize.downcase
        if type == "Form"
          form_definition_id = ctype.extra_info
        end
        if AppConfig[:assistant_controllers] and AppConfig[:assistant_controllers].include?(ctype.name)
          link_hash = { :controller => AppConfig[:assistant_controllers][ctype.name] }
        elsif AppConfig[:wizard_for] && AppConfig[:wizard_for].include?(ctype.name)
          link_hash = {:controller => "content", :action => "wizard_#{ctype.name.rubify}", :id => param_id, :type_id => ctype.id, :form_definition_id => form_definition_id }
        else
          type_hash = ( MediaItem::ALLOWED_CLASS_NAMES.include?(ctype.extra_info) ? { :type => ctype.extra_info } : {} )
          link_hash = { :controller => ctrl, :action => action, :id => param_id, :type_id => ctype.id, :form_definition_id => form_definition_id }.merge(type_hash)
        end
    end
end
