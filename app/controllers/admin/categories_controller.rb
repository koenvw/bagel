class Admin::CategoriesController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    # Order categories by lft to make them faster to display
    @categories = Category.find(:all, :order => 'lft ASC')
  end

  def new
    # FIXME:
    c = Category.find(params[:id])
    @category = Category.new
    @category.parent_id = c.id
    render :controller => 'categories', :action => 'edit'
  end

  def edit
    @category = Category.find_by_id(params[:id]) || Category.new
    if request.post?
      @category.attributes = params[:category]
      if @category.save
        if params[:parent_id].to_i > 0
          @category.move_to_child_of(params[:parent_id])
        end
        flash[:notice] = 'Category was successfully updated.'
        redirect_to :controller => 'categories', :action => 'list'
      end
    end
  end

  def destroy
    Category.find(params[:id]).destroy
    redirect_to :controller => 'categories', :action => 'list'
  end

  def sort
    Category.find(:all).each do |category|
      category.position = params["sortlist"].index(category.id.to_s) + 1
      category.save
    end
    render :nothing => true
  end

  def sort_children
    @category = Category.find(params[:id])
    @category.sort_children
    redirect_to :controller => 'categories', :action => 'list'
  end

  def save_nodes
    save_string = params[:saveString].gsub("10000-0,","") # remove root
    save_string.gsub!("10000","0")
    i = 1
    save_string.split(",").each do |element|
     category_id = element.split("-")[0]
     parent_id = element.split("-")[1]
     c = Category.find(category_id)
     if parent_id.to_i > 0
       c.move_to_child_of(parent_id)
     else
       # FIXME: this doesn't work
       c.move_to_child_of(category_id)
     end
     c.save
     i += 1
    end
    flash[:notice] = 'Categories saved.'
    redirect_to :controller => 'categories', :action => 'list'
  end

end
