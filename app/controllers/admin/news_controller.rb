class Admin::NewsController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_news_management,:_content_management]
  uses_tiny_mce tinymce_options

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  def edit
    @news = News.find_by_id(params[:id]) || News.new
    @news.type_id ||= params[:type_id]
    if request.post?
      # FIXME: this is project specific -> put in before filter ?
      # some magic voodoo for converting breaklines to paragraphs
      #body = params[:news]["body"]
      #ody.gsub!("<br /><br />","<br />")
      #ody.gsub!("<br />","</p><p>")
      #ody = "<p>#{body}" unless body[0..2] == "<p>"
      #params[:news]["body"] = body

      @news.attributes = params[:news]
      @news.prepare_sitems(params[:sitems])

      News.transaction do
        if @news.save
          @news.save_tags(params[:tags])
          @news.save_relations(params[:relations])
          @news.set_updated_by(params)
          @news.save_workflow(params[:workflow_steps])
          flash[:notice] = 'Newsitem was successfully updated.'
          if params[:book_id] == ""
            redirect_to params[:referer] || {:controller => "content", :action => "list"}
          else
            redirect_to "/admin/books/edit/#{params[:book_id]}/?news_id=#{@news.id}"
          end
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
