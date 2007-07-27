class Admin::NewsController < ApplicationController

  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_news_management,:_content_management]
  uses_tiny_mce tinymce_options

  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  def index
    edit
    render :action => 'edit'
  end

  def edit
    @news = News.find_by_id(params[:id]) || News.new
    @news.type_id ||= params[:type_id]
    if request.post?
      old_attributes = @news.attributes
      is_new_item = @news.id.blank?

      @news.attributes = params[:news]
      @news.prepare_sitems(params[:sitems])

      News.transaction do
        if @news.save
          # Save other stuff
          @news.save_tags(params[:tags])
          @news.save_relations(params[:relations])
          @news.set_updated_by(params)
          @news.save_workflow(params[:workflow_steps])

          # Log
          diff = old_attributes.inspect_with_newlines.html_diff_with(@news.attributes.inspect_with_newlines)
          bagel_log :message    => "News item #{is_new_item ? 'created' : 'updated'}",
                    :kind       => 'data',
                    :severity   => :low,
                    :extra_info => { :diff => diff, :news => @news }

          # Done
          flash[:notice] = 'Newsitem was successfully updated.'
          redirect_to params[:referer] || {:controller => "content", :action => "list"} 
        end
      end
    end
  end

  def destroy
    News.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end

end
