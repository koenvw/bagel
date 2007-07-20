class Admin::GeneratorsController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_generators_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    conditions = "1=1"
    conditions << " AND website_id = #{params[:website_id]}" unless params[:website_id].nil_or_empty?
    conditions << " AND generator_folder_id = #{params[:id]}" unless params[:id].nil?
    @generator_pages, @generators = paginate :generator, :per_page => 9999, :order => "name asc", :conditions => conditions
    @websites = Website.find(:all)
  end

  def edit
    @generator = Generator.find_by_id(params[:id]) || Generator.new
    if request.post?
      @generator.attributes = params[:generator]
      #render :inline => "<%= debug params %>" and return
      if @generator.save
        flash[:notice] ='Generator was successfully updated.'
        redirect_to :action => 'list', :id => params[:folder_id], :website_id => params[:website_id]
      end
    end
  end

  def destroy
    Generator.find(params[:id]).destroy
    redirect_to :controller => 'generators', :action => 'list', :website_id => params[:website_id]
  end

end
