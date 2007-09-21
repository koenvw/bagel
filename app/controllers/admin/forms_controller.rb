class Admin::FormsController < ApplicationController
  requires_authorization :actions => [:index, :list, :show, :clone_form, :edit, :destroy, :create, :update, :export_csv],
                         :permission => [:content_forms_management,:_content_management]
  #helper :date_picker
  uses_tiny_mce tinymce_options

  before_filter :auto_complete_for_form

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @formdef = FormDefinition.find(params[:id])
    @form_pages, @forms = paginate :form, :per_page => 10, :conditions => ["form_definition_id=?",params[:id]], :order => "created_on DESC"
  end

  # this generates dynamic auto_complete_for methods.
  def auto_complete_for_form
    return if session[:form_definition_id].nil?
    return unless FormDefinition.exists?(session[:form_definition_id])
    @formdef = FormDefinition.find(session[:form_definition_id])
    @formdef.template.scan(/bagel_auto_complete_field :[a-z_]*/).each do |m|
      object = 'form'
      method = m.split(' ')[1].strip.gsub(':','')
      logger.debug "defining: auto_complete_for_#{object}_#{method}"
      self.class.send(:define_method, "auto_complete_for_#{object}_#{method}".to_sym) do
        @entries = []
        @formdef.forms.each {|form|  @entries << form.attributes["data"] }
        #@entries.delete_if {|val| not val[method].include?(params[object][method])}
        #render :inline => "<ul style=\"z-index: 666;\"><% @entries.each do |entry|%><li><%= entry[\"production\"] %></li><% end %></ul>"
        render :inline => "<%= auto_complete_result @entries, '#{method}', '#{params[object][method]}' %>"
      end
    end
  end

  def edit
    render_404 if params[:id].blank? && (params[:form_definition_id].blank? or params[:type_id].blank?)
    @form = Form.find_by_id(params[:id]) || Form.new
    @form.form_definition_id ||= params[:form_definition_id]
    @form.type_id ||= params[:type_id]
    session[:form_definition_id] = @form.form_definition_id # for autocomplete

    # Prepare languages
    @languages = Setting.languages
  end

  def update
    # Prepare languages
    @languages = Setting.languages

    @form = Form.find_by_id(params[:id]) || Form.new

    # store current attributes for diffing
    old_attributes = @form.attributes
    is_new_item = @form.id.blank?

    # set attributes
    @form.name = params[:form][:name]
    @form.data = params[:form]
    @form.type_id = params[:form][:type_id]
    @form.form_definition_id = params[:form_definition_id]

    @form.prepare_sitems(params[:sitems])

    @form.save(false)
    @form.save_workflow(params[:workflow_steps])
    @form.save_tags(params[:tags])
    @form.save_relations(params[:relations])
    @form.set_updated_by(params)

    # Save language
    @form.save_language(params[:sobject][:language])
    @form.sobject.publish_synced = params[:publish_synced] ? true : false

    if @form.save

      # Create translated items if necessary
      # FIXME this is duplicated in news controller... perhaps move this elsewhere?
      language_codes = (params[:requested_translations] || {}).keys.map(&:to_s)
      language_codes.each do |language_code|
        # Skip language when there is already an existing object
        next if @form.sobject.language == language_code
        next unless @form.sobject.relations_as_from.select { |r| r.to.language == language_code }.empty?

        Form.transaction do
          # Clone object
          new_form = Form.new
          new_form.form_definition_id = @form.form_definition_id
          new_form.form               = @form.form
          new_form.data               = @form.data
          new_form.name               = @form.name + " [Untranslated #{Setting.language_name_for_code(language_code)}]"
          new_form.prepare_sobject

          # Clone sobject
          new_form.sobject.language         = language_code.to_s
          new_form.sobject.content_type     = @form.sobject.content_type
          new_form.sobject.content_type_id  = @form.sobject.content_type_id
          new_form.sobject.created_by       = @form.sobject.created_by
          new_form.sobject.updated_by       = @form.sobject.updated_by

          new_form.sobject.save
          new_form.save

          # Clone tags
          @form.sobject.tags.each { |tag| new_form.sobject.tags << tag }

          # Clone relationships
          @form.sobject.relations_as_from.each do |relationship|
            new_relationship = relationship.clone
            new_relationship.from_sobject_id = new_form.sobject.id
            new_relationship.save
          end
          @form.sobject.relations_as_to.each do |relationship|
            new_relationship = relationship.clone
            new_relationship.to_sobject_id = new_form.sobject.id
            new_relationship.save
          end

          # Create two translation relationships
          # FIXME Try to change relations in such a way that many-to-many relations are possible
          relation = Relation.find_by_name("Translation - #{@form.sobject.ctype.name}")
          raise "Unable to find relation named 'Translation - #{@form.sobject.ctype.name}'" if relation.nil?
          @form.add_relation_unless(new_form.sobject.id, relation.id)

        end
      end

      # Share on del.icio.us
      share_on_delicious(@form, params[:sharing_delicious_site]) if params[:sharing_delicious]

      # Log
      diff = old_attributes.inspect_with_newlines.html_diff_with(@form.attributes.inspect_with_newlines)
      bagel_log :message    => "Template #{is_new_item ? 'created' : 'updated'}",
                :kind       => 'data',
                :severity   => :low,
                :extra_info => { :diff => diff }

      flash[:notice] = 'Form was successfully updated.'
      redirect_to params[:referer] || {:controller => "content", :action => "list"}
    else
      render :action => "edit"
    end
  end

  def destroy
    f = Form.find(params[:id])
    f.destroy
    redirect_to :back
  end

  def export_csv
    @formdef = FormDefinition.find(params[:id])
    @forms = Form.find_all_by_form_definition_id(params[:id])
    @csv = render_to_string :action => "export_csv", :layout => false

    send_data @csv, :type => 'application/vnd.ms-excel', :filename => @formdef.name.rubify + "_" + Date.today.strftime("%Y%m%d") + ".xls"
  end

  def render_tpl(tpl)
    # FIXME: this sub only works because we call render_tpl from the template
    render_to_string :inline => tpl.sub(/<%=\s+submit_tag\s+('|")\w+('|")\s+%>/,"")
  end

end
