class Admin::LogMessagesController < ApplicationController

  requires_authorization :actions => [ :index, :show, :destroy ], :permission => [ :admin_log_management ]

  def index
    conditions = {}
    conditions[:kind] = params[:kind] if params[:kind]
    conditions[:severity] = params[:severity_id] if params[:severity_id]
    conditions = nil if conditions.size == 0

    @log_message_pages, @log_messages = paginate :log_messages, :per_page => 20, :order => 'created_at DESC',
                                                 :conditions => conditions
  end

  def show
    @log_message = LogMessage.find(params[:id])
  end

  def destroy
    if request.post?
      LogMessage.find(params[:id]).destroy
      flash[:notice] = 'The log message was successfully deleted.'
    end
    redirect_to :action => :index
  end

  def rotate
    if request.post?
      LogMessage.rotate
    end
    redirect_to :action => :index
  end

end
