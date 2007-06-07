class Admin::EventsController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_events_management,:_content_management]
  uses_tiny_mce tinymce_options

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  def edit
    @event = Event.find_by_id(params[:id]) || Event.new
    if request.post?
      @event.attributes = params[:event]
      @event.prepare_sitems(params[:sitems])

      Event.transaction do
        if @event.save
          @event.save_tags(params[:tags])
          @event.save_relations(params[:relations])
          @event.set_updated_by(params)
          flash[:notice] = 'Event was successfully updated.'
          redirect_to params[:referer] || {:controller => "content", :action => "list"}
        end
      end
    end
  end

  def destroy
    Event.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end

end
