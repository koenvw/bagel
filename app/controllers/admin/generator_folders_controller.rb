class Admin::GeneratorFoldersController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_folder_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @folders = GeneratorFolder.find(:all,:order => "lft")
  end

  def edit
    @folder = GeneratorFolder.find_by_id(params[:id]) || GeneratorFolder.new
    @folder.website_id ||= params[:website_id]
    if request.post?
      @folder.attributes = params[:folder]
      if @folder.save
        @folder.to_child_of(params[:parent_id])
        flash[:notice] = 'Folder was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    GeneratorFolder.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

end
