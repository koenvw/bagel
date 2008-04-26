class Admin::ExportController < ApplicationController
  
  
  requires_authorization :actions => [:edit, :export],
                         :permission => [:_admin_management]


  def edit
  
  end
  
  def export
    @res= Sobject.find :all,:conditions=>["content_type_id=?",params[:selected_content_type]],:limit=>100
    if(params[:selected_format]=="XML")
      send_data @res.to_xml, :filename => 'export.xml' 
    end
  end

  
  
end