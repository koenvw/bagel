
class Admin::CommentsController < ApplicationController


  def index
    list
    render :action => 'list'
  end



end
