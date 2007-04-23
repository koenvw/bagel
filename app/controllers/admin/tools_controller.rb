class Admin::ToolsController < ApplicationController
  requires_authorization :actions => [:index],
                         :permission => [:admin_tools_management,:_admin_management]

  def index
  end
end
