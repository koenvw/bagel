class Admin::ContentController < ApplicationController

  requires_authorization  :actions => [ :index, :list, :wizard ], :permission => [ :_content_management ]

  uses_tiny_mce           tinymce_options

  def index
    list
    render :action => 'list'
  end

  def list
    if params[:publish_date]
      publish_from = params[:publish_date].to_time.at_beginning_of_day
      publish_till = params[:publish_date].to_time.tomorrow.at_beginning_of_day
    else
      publish_from = nil
      publish_till = nil
    end

    # Find all items
    nonpaginated_items = Sobject.find_with_parameters(
      :status           => :all,
      :content_types    => params[:type_id],
      :tags             => params[:tag_id],
      :website_id       => params[:website_id],
      :published_by     => params[:user_id],
      :current_workflow_step => params[:step_id],
      :publish_from     => publish_from,
      :publish_till     => publish_till,
      :limit            => 1000,
      :order            => "sitems.publish_date DESC, sobjects.id DESC",
      :search_string    => params[:search_string]
    )

    # Paginate items
    @item_pages, @items = paginate_collection(nonpaginated_items, :page => params[:page], :per_page => 25 )

    # Find all content types except generators
    @content_types = ContentType.find(:all, :conditions => "hidden=0", :order => "name")

    # Find all web sites
    @websites = Website.find(:all, :order => "name")
  end

  def wizard
    # Find all content types except generators
    @content_types = ContentType.find(:all, :conditions => "hidden=0", :order => "name")
  end

end
