require File.dirname(__FILE__) + '/../test_helper'

class NewsTest < Test::Unit::TestCase
  fixtures :news
  fixtures :sitems
  
  def setup
    @news = News.new
    @news.title = "Title"
    @news.body = "Body"
  end

  def test_sitems_for_new_record
    # by default 1 published sitem is created for each website
    number_of_sitems = Website.find(:all).size
    assert @news.sitems.size > 0
    assert_equal @news.sitems.size, number_of_sitems
    @news.sitems.each do |sitem|
      assert_equal "1", sitem.status
    end
  end


end
