class Admin::BusinessRulesController < ApplicationController

  requires_authorization :actions => [:index, :edit, :destroy, :report],
                         :permission => [:admin_business_rules_management,:_admin_management]

  def index
    @business_rules = BusinessRule.find(:all)
  end 

  def edit
    @business_rule = BusinessRule.find_by_id(params[:id]) || BusinessRule.new
    @content_types = ContentType.find(:all, :order => 'name')

    if request.post?
      @business_rule.attributes = params[:business_rule]
      @business_rule.content_type = ContentType.find_by_id(params[:business_rule][:content_type_id])

      if @business_rule.save
        # Log
        bagel_log :message    => "Business rule created",
                  :kind       => 'data',
                  :severity   => :low,
                  :extra_info => { :business_rule => @business_rule.attributes }

        flash[:notice] = 'Business rule was successfully created.'
        redirect_to :action => 'index'
      end
    end
  end

  def destroy
    @business_rule = BusinessRule.find(params[:id])
    @business_rule.destroy
    
    redirect_to :action => 'index'
  end

  def report
    @business_rule = BusinessRule.find_by_id(params[:id])
    @object_pages, @objects = paginate_collection(@business_rule.non_matching_objects, :page => params[:page], :per_page => 25 )
  end

end
