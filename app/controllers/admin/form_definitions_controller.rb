class Admin::FormDefinitionsController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_form_definitions_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @form_definition_pages, @form_definitions = paginate :form_definition, :per_page => 20, :order => "name ASC"
  end

  def edit
    @form_definition = FormDefinition.find_by_id(params[:id]) || FormDefinition.new
    if request.post?
      @form_definition.attributes = params[:form_definition]
      if @form_definition.save
        flash[:notice] = 'Form was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    FormDefinition.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :action => 'list'
  end

end
