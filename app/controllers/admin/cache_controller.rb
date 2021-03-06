class Admin::CacheController < ApplicationController
  requires_authorization :actions => [:index, :flush],
                         :permission => [:admin_cache_management,:_admin_management] 

  def index
    @stats = CACHE.stats rescue @stats = []
  end 

  def flush
    CACHE.flush_all
    redirect_to :action => index
  end

end
