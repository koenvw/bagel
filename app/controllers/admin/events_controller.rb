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
    # Find or create event
    @event = Event.find_by_id(params[:id]) || Event.new
    @event.type_id ||= params[:type_id]
    @event.create_default_sitems
    
    if request.post?
      old_attr = {
        :container          => @event.attributes,
        :sitems             => @event.sitems.map(&:attributes),
        :sobject            => @event.sobject.attributes,
        :relations_as_from  => @event.sobject.relations_as_from.map(&:attributes),
        :relations_as_to    => @event.sobject.relations_as_to.map(&:attributes),
        :tags               => @event.sobject.tags.map(&:attributes)
      }
      is_new_item = @event.id.nil?

      # Update attributes based on params
      @event.attributes = params[:event]
      @event.prepare_sitems(params[:sitems])

      # Save
      Event.transaction do
        @event.save(false)

        # Save related
        @event.save_tags(params[:tags])
        @event.save_relations(params[:relations])
        @event.set_updated_by(params)

        if @event.save
          # Share on del.icio.us
          share_on_delicious(@event, params[:sharing_delicious_site]) if params[:sharing_delicious]

          # Log
          new_attr = {
            :container          => @event.attributes,
            :sitems             => @event.sitems.map(&:attributes),
            :sobject            => @event.sobject.attributes,
            :relations_as_from  => @event.sobject.relations_as_from.map(&:attributes),
            :relations_as_to    => @event.sobject.relations_as_to.map(&:attributes),
            :tags               => @event.sobject.tags.map(&:attributes)
          }
          diff = old_attr.inspect_with_newlines.html_diff_with(new_attr.inspect_with_newlines)
          bagel_log :message    => "Event #{is_new_item ? 'created' : 'updated'}",
                    :kind       => 'data',
                    :severity   => :low,
                    :extra_info => (is_new_item ? new_attr : { :diff => diff })

          # Done
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
