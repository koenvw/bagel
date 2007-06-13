class Admin::WorkflowStepsController < ApplicationController
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
    @workflow_steps_pages, @workflow_steps = paginate :workflow_steps, :per_page => 100, :order => "position", :conditions => ["workflow_id = ?", params[:id]]
  end

  def edit
    @workflow_step = WorkflowStep.find_by_id(params[:id]) || WorkflowStep.new
    if request.post?
      @workflow_step.attributes = params[:workflow_step]
      if @workflow_step.save
        flash[:notice] ='Workflowstep was successfully updated.'
        redirect_to :action => 'list', :id => @workflow_step.workflow_id
      end
    end
  end

  def destroy
    WorkflowStep.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

end
