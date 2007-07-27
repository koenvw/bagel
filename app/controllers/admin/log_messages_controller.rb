class Admin::LogMessagesController < ApplicationController

  requires_authorization :actions => [ :index, :show, :destroy ], :permission => [ :admin_log_management ]

  def index
    @log_message_pages, @log_messages = paginate :log_messages, :per_page => 20, :order => 'created_at DESC'
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
