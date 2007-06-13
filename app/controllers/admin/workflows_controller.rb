class Admin::WorkflowsController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_workflow_management,:_admin_management]
  layout "application", :only => [:index,:list,:edit,:destroy]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @workflows_pages, @workflows = paginate :workflow, :per_page => 100, :order => "name"
  end

  def edit
    @workflow = Workflow.find_by_id(params[:id]) || Workflow.new
    if request.post?
      params[:workflow][:content_type_ids] ||= []
      @workflow.attributes = params[:workflow]
      if @workflow.save
        flash[:notice] ='Workflow was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    Workflow.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

end
