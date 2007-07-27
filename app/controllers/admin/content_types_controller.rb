class Admin::ContentTypesController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_content_types_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @types_pages, @types = paginate :content_type, :per_page => 100, :order => "name"
  end

  def edit
    # Find or create content type
    @type = ContentType.find_by_id(params[:id]) || ContentType.new

    if request.post?
      old_attr = { :content_type => @type.attributes }
      is_new_item = @type.id.nil?

      # Update attributes based on params
      @type.attributes = params[:type]

      # Save
      if @type.save
        # Log
        new_attr = { :content_type => @type.attributes }
        diff = old_attr.inspect_with_newlines.html_diff_with(new_attr.inspect_with_newlines)
        bagel_log :message    => "Content Type #{is_new_item ? 'created' : 'updated'}",
                  :kind       => 'data',
                  :severity   => :low,
                  :extra_info => (is_new_item ? new_attr : { :diff => diff })

        # Done
        flash[:notice] ='content type was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    ContentType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

end
