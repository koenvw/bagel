class Admin::ContainersController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_container_management,:_content_management]
  uses_tiny_mce tinymce_options

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  def edit
    # Find or create container
    @container = Container.find_by_id(params[:id]) || Container.new
    @container.type_id ||= params[:type_id]

    if request.post?
      old_attr = {
        :container          => @container.attributes,
        :sitems             => @container.sitems.map(&:attributes),
        :sobject            => @container.sobject.attributes,
        :relations_as_from  => @container.sobject.relations_as_from.map(&:attributes),
        :relations_as_to    => @container.sobject.relations_as_to.map(&:attributes),
        :tags               => @container.sobject.tags.map(&:attributes)
      }
      is_new_item = @container.id.nil?

      # Update attributes based on params
      @container.attributes = params[:container]
      @container.prepare_sitems(params[:sitems])

      # Save
      Container.transaction do
        if @container.save
          # Save related
          @container.save_workflow(params[:workflow_steps])
          @container.save_tags(params[:tags])
          @container.save_relations(params[:relations])
          @container.set_updated_by(params)

          # Log
          new_attr = {
            :container          => @container.attributes,
            :sitems             => @container.sitems.map(&:attributes),
            :sobject            => @container.sobject.attributes,
            :relations_as_from  => @container.sobject.relations_as_from.map(&:attributes),
            :relations_as_to    => @container.sobject.relations_as_to.map(&:attributes),
            :tags               => @container.sobject.tags.map(&:attributes)
          }
          diff = old_attr.inspect_with_newlines.html_diff_with(new_attr.inspect_with_newlines)
          bagel_log :message    => "Container #{is_new_item ? 'created' : 'updated'}",
                    :kind       => 'data',
                    :severity   => :low,
                    :extra_info => (is_new_item ? new_attr : { :diff => diff })

          # Done
          flash[:notice] ='Container was successfully updated.'
          redirect_to params[:referer] || {:controller => "content", :action => "list"}
        end
      end
    end
  end

  def destroy
    Container.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end
end
