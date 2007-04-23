class Admin::MenusController < ApplicationController
  requires_authorization :actions => [:index, :list, :new, :edit, :destroy],
                         :permission => [:content_menu_management,:_content_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @menu_pages, @menus = paginate :menu, :per_page => 100, :order_by => 'lft ASC'
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
        @menu.to_child_of(params[:parent_id])
        flash[:notice] = 'Menu was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    Menu.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  #
  def move_up
    Menu.move_up(params[:id])
    redirect_to :action => 'list'
  end
  def move_down
    Menu.move_down(params[:id])
    redirect_to :action => 'list'
  end
  def move_left
    Menu.move_left(params[:id])
    redirect_to :action => 'list'
  end
  def move_right
    Menu.move_right(params[:id])
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
