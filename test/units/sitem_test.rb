require File.dirname(__FILE__) + '/../test_helper'

class SitemTest < Test::Unit::TestCase
  fixtures :sitems

  def setup
    @sitem = Sitem.find(1)
  end

  # Replace this with your real tests.
  def test_create
    assert_equal 1, @sitem.id
  end
end
