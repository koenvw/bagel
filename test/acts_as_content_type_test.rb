require 'test_helper'

class ActsAsContentTypeTest < Test::Unit::TestCase #:nodoc:
  fixtures :news
  fixtures :categories
  fixtures :tags
  fixtures :sobjects

  def setup
    @news_new = News.new
    @news = news(:first)
    #@node_without_children  = categories(:node_without_children)
  end

  def test_construction #:nodoc:

    # check sobject
    assert_respond_to @news_new, :sobject
    assert_not_nil @news_new.sobject

    # check sitems
    assert_respond_to @news_new, :sitems

  end
  def test_save_tags
    tags_array = [1,2]
    @news.save_tags(tags_array)
    @news.reload
    assert_equal 2, @news.tags.size
    tags_array = "1,2"
    @news.save_tags(tags_array)
    @news.reload
    assert_equal 2, @news.tags.size
    
  end
end
