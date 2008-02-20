class Comment < ActiveRecord::Base
  
  has_and_belongs_to_many :sobjects, :join_table => "sobjects_comments"
  belongs_to :admin_user

  validates_presence_of   :body
  validates_presence_of   :admin_user_id

  
end
