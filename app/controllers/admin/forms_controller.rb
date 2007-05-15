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
    @formdef.template.scan(/text_field_with_auto_complete :form, :[a-z_]*/).each do |m|
      object = 'form'
      method = m.split(',')[1].strip.gsub(':','')
      logger.debug "defining: auto_complete_for_#{object}_#{method}"
      self.class.send(:define_method, "auto_complete_for_#{object}_#{method}".to_sym) do
        @entries = []
        Form.find(:all).each {|form| @entries << form.data if form.data.has_key?(method) }
        @entries.delete_if {|val| not val[method].include?(params[object][method])}
        render :inline => "<%= auto_complete_result @entries, '#{method}', '#{params[object][method]}' %>"
      end
    end
  end

  def show
    @formdef = FormDefinition.find(params[:id])
    session[:form_definition_id] = params[:id] # for autocomplete
    str = '<div id="breadcrumb"><%= link_to "Forms", :controller => "form_definitions" %> > <%= link_to @formdef.name, :controller => "forms", :action => "list", :id => @formdef %> > new form </div>'
    str << "<%= start_form_tag :action => 'create', :id => @formdef %>"
    str << @formdef.template
    str << "<%= end_form_tag %>"
    render :inline => str, :layout => true
  end

  def edit
    @form = Form.find(params[:id])
    session[:form_definition_id] = @form.form_definition_id # for autocomplete
  end

  def clone_form
    @f = Form.find(params[:id])
    @form = @f.clone
    session[:form_definition_id] = @form.form_definition_id # for autocomplete
    str = '<div id="breadcrumb"><%= link_to "Forms", :controller => "form_definitions" %> > <%= link_to @form.form_definition.name, :controller => "forms", :action => "list", :id => @form.form_definition_id %> > <%= @form.name %> (clone) </div>'
    str << "<%= start_form_tag :action => 'create', :id => @form.form_definition_id %>"
    str << @form.form_definition.template
    str << "<%= end_form_tag %>"
    render :inline => str, :layout => true
  end

  def create
    @formdef = FormDefinition.find(params[:id])
    @form = Form.new
    @form.form_definition_id = @formdef.id
    @form.name = params[:form][:name]
    @form.data = params[:form]
    @form.form = @formdef.template
    if @form.save
      flash[:notice] = 'Form was successfully created.'
      unless @formdef.redirect_to == ""
        redirect_to @formdef.redirect_to
      else
        redirect_to :action => 'list', :id => params[:id]
      end
    end
  end

  def update
    @form = Form.find(params[:id])
    @form.name = params[:form][:name]
    @form.data = params[:form]
    @form.prepare_sitems(params[:sitems])
    if @form.save
      @form.save_tags(params[:tags])
      @form.save_tags(params[:relations])
      @form.set_updated_by(params)
      flash[:notice] = 'Form was successfully updated.'
      if params[:redirect]
        redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
      else
        redirect_to :action => 'list', :id => @form.form_definition_id
      end
    end
  end

  def destroy
    f = Form.find(params[:id])
    form_def_id = f.form_definition_id
    f.destroy
    if params[:redirect]
      redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
    else
      redirect_to :action => 'list', :id => form_def_id
    end
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
