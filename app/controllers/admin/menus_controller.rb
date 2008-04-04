class Admin::MenusController < ApplicationController
  requires_authorization :actions => [:index, :list, :list2, :new, :edit, :destroy],
                         :permission => [:content_menu_management,:_content_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list2
    list
  end

  def list
    @menu_pages, @menus = paginate :menu, :order_by => 'lft ASC'
    @menu = Menu.find(params[:id]) unless params[:id].nil?
  end

  def new
    #FIXME: can not set parent_id
    c = Menu.find(params[:id])
    @menu = Menu.new
    @menu.parent_id = c.id
    params[:position_new] = c.position + 1
    render :action => 'edit'
  end

  def edit
    @menu = Menu.find_by_id(params[:id]) || Menu.new
    if request.post?
      @menu.attributes = params[:menu]
      @menu.prepare_sitems(params[:sitems])
      if @menu.save
        @menu.save_relations(params["relations"])
        @menu.to_child_of(params[:parent_id]) if @menu.parent_id.to_s != params[:parent_id]
        @menu.move_to_right_of(params[:move_below]) if !params[:move_below].blank? && params[:move_below]!="0"
        @menu.move_to_left_of(params[:move_above]) if !params[:move_above].blank? && params[:move_above]!="0"
        flash[:notice] = 'Menu was successfully updated.'
        redirect_to :action => 'list2'
      end
    end
  end

  def destroy
    Menu.find(params[:id]).destroy
    redirect_to :back
  end

  #
  def move_up
    m = Menu.find(params[:id])
    m.move_up(params[:id])
    redirect_to :action => 'list'
  end
  def move_left
    m = Menu.find(params[:id])
    m.move_left
    redirect_to :action => 'list'
  end
  def move_right
    m = Menu.find(params[:id])
    m.move_right(params[:id])
    redirect_to :action => 'list'
  end

  def sort
    Menu.find(:all).each do |menu|
      menu.position = params["sortlist"].index(menu.id.to_s) + 1
      menu.save
    end
    render :nothing => true
  end

end
