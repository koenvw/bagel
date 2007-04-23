class Admin::BooksController < ApplicationController
  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_book_management,:_content_management]
  uses_tiny_mce tinymce_options

  def index
    edit
    render :action => 'edit'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :update ],
         :redirect_to => { :action => :edit }

  def edit
    if params[:id].nil?
      @book = Book.new
    else
      @book = Book.find(params[:id])
    end

    # check if we need to set a relation to a given news_id
    unless params[:news_id].nil?
      # FIXME: this is project specific!
      book_cat = Relation.find_or_create_by_name('Dossier subpage')
      news=News.find(params[:news_id])
      rel = @book.sobject.create_in_relations_as_from :to =>news.sobject,:category=>book_cat
      rel.move_to_bottom
      flash[:notice] = "Newsitem \"#{news.title}\" added to Book."
      redirect_to :action => 'edit', :id => @book
    end

    # save book
    if request.post?
      @book.attributes = params[:book]
      @book.prepare_sitems(params[:sitems], params[:sitems_new])
      if @book.save
        @book.save_tags(params["tags"])
        @book.save_relationships(params["relationsout_id"],params["relationsout_cat_id"],params["relsout_del_id"],params["relsout_del_cat_id"],true)
        @book.save_relationships(params["relationsin_id"],params["relationsin_cat_id"],params["relsin_del_id"],params["relsin_del_cat_id"])
        @book.set_updated_by(params)
        flash[:notice] = 'Book was successfully updated.'
        if params[:redirect]
          redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
        else
          redirect_to :controller => "content", :action => 'list', :id => @book
        end
      else
        render :action => 'edit'
      end
    end

  end

  def destroy
    Book.find(params[:id]).destroy
    if params[:redirect]
      redirect_to params[:redirect]+"?website_id=#{params[:website_id]}&search_string=#{params[:search_string]}&content_type=#{params[:content_type]}"
    else
      redirect_to :controller => "content", :action => 'list'
    end
  end

end
