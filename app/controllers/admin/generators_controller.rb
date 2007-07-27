require 'erb'

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
    conditions << " AND website_id = #{params[:website_id]}" unless params[:website_id].blank?
    conditions << " AND generator_folder_id = #{params[:id]}" unless params[:id].nil?
    @generator_pages, @generators = paginate :generator, :per_page => 9999, :order => "name asc", :conditions => conditions
    @websites = Website.find(:all)
  end

  def edit
    # Find or create generator
    @generator = Generator.find_by_id(params[:id]) || Generator.new

    if request.post?
      old_attributes = @generator.attributes
      is_new_item = @generator.id.blank?

      # Update generator
      @generator.attributes = params[:generator]
      if @generator.save
        # Log
        diff = old_attributes.inspect_with_newlines.html_diff_with(@generator.attributes.inspect_with_newlines)
        bagel_log :message    => "Generator #{is_new_item ? 'created' : 'updated'}",
                  :kind       => 'data',
                  :severity   => :low,
                  :extra_info => { :diff => diff, :generator => @generator }

        flash[:notice] ='Generator was successfully updated.'
        redirect_to :action => 'list', :id => params[:folder_id], :website_id => params[:website_id]
      end
    else
      @generator.website = Website.find(params[:website_id]) unless @generator.website
    end
  end

  def destroy
    Generator.find(params[:id]).destroy
    redirect_to :controller => 'generators', :action => 'list', :website_id => params[:website_id]
  end

end
